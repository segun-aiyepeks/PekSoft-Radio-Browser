import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/library_repository.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';

/// Local-first [LibraryRepository] backed by [AppDatabase] and guarded by
/// [EntitlementRepository] limits.
class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl({
    required AppDatabase database,
    required this._entitlementRepository,
    DateTime Function()? now,
  }) : _db = database,
       _now = now ?? DateTime.now;

  final AppDatabase _db;
  final EntitlementRepository _entitlementRepository;
  final DateTime Function() _now;

  @override
  Future<Result<List<Station>>> getFavourites() async {
    try {
      final List<String> ids = await _db.getFavouriteIds();
      return Success<List<Station>>(await _db.getCachedStationsByIds(ids));
    } catch (error) {
      return Failure<List<Station>>(
        AppFailure.storage(message: 'Failed to load favourites: $error'),
      );
    }
  }

  @override
  Future<Result<bool>> isFavourite(String stationId) async {
    try {
      final List<String> ids = await _db.getFavouriteIds();
      return Success<bool>(ids.contains(stationId));
    } catch (error) {
      return Failure<bool>(
        AppFailure.storage(message: 'Failed to check favourite: $error'),
      );
    }
  }

  @override
  Future<Result<void>> addFavourite(Station station) async {
    try {
      final List<String> currentIds = await _db.getFavouriteIds();
      if (!currentIds.contains(station.id)) {
        final Entitlement entitlement = await _currentEntitlement();
        final int maxFavs = entitlement.maxFavourites;
        if (entitlement.tier == EntitlementTier.free &&
            currentIds.length >= maxFavs) {
          return Failure<void>(
            AppFailure.entitlementRequired(
              message:
                  'Free tier allows up to $maxFavs favourites. Upgrade to save more.',
            ),
          );
        }
      }
      final DateTime now = _now();
      await _db.upsertStations(<Station>[station], now: now);
      await _db.addFavourite(station.id, now: now);
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to add favourite: $error'),
      );
    }
  }

  @override
  Future<Result<void>> removeFavourite(String stationId) async {
    try {
      await _db.removeFavourite(stationId);
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to remove favourite: $error'),
      );
    }
  }

  @override
  Future<Result<List<Station>>> getRecents({int limit = 50}) async {
    try {
      final List<String> ids = await _db.getRecentIds(limit: limit);
      return Success<List<Station>>(await _db.getCachedStationsByIds(ids));
    } catch (error) {
      return Failure<List<Station>>(
        AppFailure.storage(message: 'Failed to load recents: $error'),
      );
    }
  }

  @override
  Future<Result<void>> recordRecent(Station station) async {
    try {
      final DateTime now = _now();
      await _db.upsertStations(<Station>[station], now: now);
      await _db.recordRecent(station.id, now: now);
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to record recent: $error'),
      );
    }
  }

  @override
  Future<Result<List<Collection>>> getCollections() async {
    try {
      return Success<List<Collection>>(await _db.getCollections());
    } catch (error) {
      return Failure<List<Collection>>(
        AppFailure.storage(message: 'Failed to load collections: $error'),
      );
    }
  }

  @override
  Future<Result<void>> saveCollection(Collection collection) async {
    try {
      if (!collection.isCurated) {
        final List<Collection> existing = await _db.getCollections();
        final List<Collection> userCollections = existing
            .where((Collection c) => !c.isCurated)
            .toList(growable: false);
        final bool isUpdating = userCollections.any(
          (Collection c) => c.id == collection.id,
        );
        if (!isUpdating) {
          final Entitlement entitlement = await _currentEntitlement();
          final int maxCols = entitlement.maxCollections;
          if (entitlement.tier == EntitlementTier.free &&
              userCollections.length >= maxCols) {
            return Failure<void>(
              AppFailure.entitlementRequired(
                message:
                    'Free tier allows up to $maxCols custom collections. Upgrade to create more.',
              ),
            );
          }
        }
      }
      await _db.upsertCollection(collection, now: _now());
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to save collection: $error'),
      );
    }
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) async {
    try {
      await _db.deleteCollection(collectionId);
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to delete collection: $error'),
      );
    }
  }

  @override
  Future<Result<List<SongHistoryEntry>>> getSongHistory({
    int limit = 100,
  }) async {
    try {
      final Entitlement entitlement = await _currentEntitlement();
      final int effectiveLimit =
          entitlement.tier == EntitlementTier.free &&
              entitlement.maxSongHistory < limit
          ? entitlement.maxSongHistory
          : limit;
      return Success<List<SongHistoryEntry>>(
        await _db.getSongHistory(limit: effectiveLimit),
      );
    } catch (error) {
      return Failure<List<SongHistoryEntry>>(
        AppFailure.storage(message: 'Failed to load song history: $error'),
      );
    }
  }

  @override
  Future<Result<void>> logSongHistory(SongHistoryEntry entry) async {
    try {
      await _db.insertSongHistory(entry);
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to log song history: $error'),
      );
    }
  }

  @override
  Future<Result<void>> clearSongHistory() async {
    try {
      await _db.clearSongHistory();
      return const Success<void>(null);
    } catch (error) {
      return Failure<void>(
        AppFailure.storage(message: 'Failed to clear song history: $error'),
      );
    }
  }

  Future<Entitlement> _currentEntitlement() async {
    final Result<Entitlement> res = await _entitlementRepository
        .getEntitlement();
    return switch (res) {
      Success<Entitlement>(:final data) => data,
      Failure<Entitlement>() => const Entitlement(),
    };
  }
}
