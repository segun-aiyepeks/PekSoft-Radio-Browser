import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:peksoft_radio/core/database/tables.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

part 'app_database.g.dart';

/// Metadata + payload returned from [CachedCatalogLists].
class CachedListRecord {
  const CachedListRecord({
    required this.cacheKey,
    required this.payloadJson,
    required this.cachedAt,
    required this.ttl,
  });

  final String cacheKey;
  final String payloadJson;
  final DateTime cachedAt;
  final Duration ttl;

  bool isExpiredAt(DateTime now) => now.difference(cachedAt) >= ttl;
}

/// Versioned local SQLite database powered by Drift.
@DriftDatabase(
  tables: <Type>[
    CachedStations,
    CachedCatalogLists,
    Favourites,
    Recents,
    Collections,
    CollectionStations,
    SongHistoryEntries,
    UserSettingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Creates an in-memory database for unit tests.
  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  /// Opens a persistent database backed by [file] (used in app & migration tests).
  factory AppDatabase.openFile(File file) => AppDatabase(NativeDatabase(file));

  /// Opens the default on-device database file.
  static Future<AppDatabase> openDefault() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'peksoft_radio.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  static const int maxRecents = 50;

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.addColumn(collections, collections.sortOrder);
      }
    },
  );

  // ---------------------------------------------------------------------------
  // Cached Stations
  // ---------------------------------------------------------------------------

  Future<void> upsertStations(List<Station> stations, {DateTime? now}) async {
    if (stations.isEmpty) {
      return;
    }
    final DateTime timestamp = now ?? DateTime.now();
    await batch((Batch b) {
      b.insertAllOnConflictUpdate(
        cachedStations,
        stations
            .map((Station s) => _stationToCompanion(s, timestamp))
            .toList(growable: false),
      );
    });
  }

  Future<Station?> getCachedStationById(String id) async {
    final CachedStation? row = await (select(
      cachedStations,
    )..where(($CachedStationsTable t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _stationFromRow(row);
  }

  Future<List<Station>> getCachedStationsByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return const <Station>[];
    }
    final List<CachedStation> rows = await (select(
      cachedStations,
    )..where(($CachedStationsTable t) => t.id.isIn(ids))).get();
    final Map<String, Station> byId = <String, Station>{
      for (final CachedStation row in rows) row.id: _stationFromRow(row),
    };
    return ids.map((String id) => byId[id]).whereType<Station>().toList();
  }

  Future<List<Station>> getAllCachedStations() async {
    final List<CachedStation> rows = await select(cachedStations).get();
    return rows.map(_stationFromRow).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Cached Catalog / Search Lists
  // ---------------------------------------------------------------------------

  Future<void> saveCachedList({
    required String cacheKey,
    required String payloadJson,
    required Duration ttl,
    DateTime? now,
  }) async {
    await into(cachedCatalogLists).insertOnConflictUpdate(
      CachedCatalogListsCompanion(
        cacheKey: Value<String>(cacheKey),
        payloadJson: Value<String>(payloadJson),
        cachedAt: Value<DateTime>(now ?? DateTime.now()),
        ttlSeconds: Value<int>(ttl.inSeconds),
      ),
    );
  }

  Future<CachedListRecord?> getCachedList(String cacheKey) async {
    final CachedCatalogList? row =
        await (select(cachedCatalogLists)..where(
              ($CachedCatalogListsTable t) => t.cacheKey.equals(cacheKey),
            ))
            .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return CachedListRecord(
      cacheKey: row.cacheKey,
      payloadJson: row.payloadJson,
      cachedAt: row.cachedAt,
      ttl: Duration(seconds: row.ttlSeconds),
    );
  }

  // ---------------------------------------------------------------------------
  // Favourites
  // ---------------------------------------------------------------------------

  Future<void> addFavourite(String stationId, {DateTime? now}) async {
    await into(favourites).insertOnConflictUpdate(
      FavouritesCompanion(
        stationId: Value<String>(stationId),
        createdAt: Value<DateTime>(now ?? DateTime.now()),
      ),
    );
  }

  Future<void> removeFavourite(String stationId) async {
    await (delete(
      favourites,
    )..where(($FavouritesTable t) => t.stationId.equals(stationId))).go();
  }

  Future<List<String>> getFavouriteIds() async {
    final List<Favourite> rows =
        await (select(favourites)
              ..orderBy(<OrderingTerm Function($FavouritesTable)>[
                ($FavouritesTable t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();
    return rows.map((Favourite f) => f.stationId).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Recents (capped at last 50)
  // ---------------------------------------------------------------------------

  Future<void> recordRecent(String stationId, {DateTime? now}) async {
    final DateTime playedAt = now ?? DateTime.now();
    await transaction(() async {
      await into(recents).insertOnConflictUpdate(
        RecentsCompanion(
          stationId: Value<String>(stationId),
          playedAt: Value<DateTime>(playedAt),
        ),
      );
      final List<Recent> all =
          await (select(recents)
                ..orderBy(<OrderingTerm Function($RecentsTable)>[
                  ($RecentsTable t) => OrderingTerm.desc(t.playedAt),
                ]))
              .get();
      if (all.length > maxRecents) {
        final List<String> toDelete = all
            .sublist(maxRecents)
            .map((Recent r) => r.stationId)
            .toList(growable: false);
        await (delete(
          recents,
        )..where(($RecentsTable t) => t.stationId.isIn(toDelete))).go();
      }
    });
  }

  Future<List<String>> getRecentIds({int limit = maxRecents}) async {
    final List<Recent> rows =
        await (select(recents)
              ..orderBy(<OrderingTerm Function($RecentsTable)>[
                ($RecentsTable t) => OrderingTerm.desc(t.playedAt),
              ])
              ..limit(limit))
            .get();
    return rows.map((Recent r) => r.stationId).toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Collections
  // ---------------------------------------------------------------------------

  Future<void> upsertCollection(
    Collection collection, {
    int sortOrder = 0,
    DateTime? now,
  }) async {
    final DateTime timestamp = now ?? DateTime.now();
    await transaction(() async {
      await into(collections).insertOnConflictUpdate(
        CollectionsCompanion(
          id: Value<String>(collection.id),
          title: Value<String>(collection.title),
          subtitle: Value<String>(collection.subtitle),
          isCurated: Value<bool>(collection.isCurated),
          updatedAt: Value<DateTime?>(collection.updatedAt ?? timestamp),
          sortOrder: Value<int>(sortOrder),
        ),
      );
      await (delete(collectionStations)..where(
            ($CollectionStationsTable t) =>
                t.collectionId.equals(collection.id),
          ))
          .go();
      if (collection.stationIds.isNotEmpty) {
        await batch((Batch b) {
          b.insertAll(
            collectionStations,
            collection.stationIds
                .asMap()
                .entries
                .map((MapEntry<int, String> entry) {
                  return CollectionStationsCompanion(
                    collectionId: Value<String>(collection.id),
                    stationId: Value<String>(entry.value),
                    addedAt: Value<DateTime>(
                      timestamp.add(Duration(microseconds: entry.key)),
                    ),
                  );
                })
                .toList(growable: false),
          );
        });
      }
    });
  }

  Future<void> deleteCollection(String collectionId) async {
    await transaction(() async {
      await (delete(collectionStations)..where(
            ($CollectionStationsTable t) => t.collectionId.equals(collectionId),
          ))
          .go();
      await (delete(
        collections,
      )..where(($CollectionsTable t) => t.id.equals(collectionId))).go();
    });
  }

  Future<List<Collection>> getCollections() async {
    final List<CollectionRow> rows =
        await (select(collections)
              ..orderBy(<OrderingTerm Function($CollectionsTable)>[
                ($CollectionsTable t) => OrderingTerm.asc(t.sortOrder),
                ($CollectionsTable t) => OrderingTerm.desc(t.updatedAt),
              ]))
            .get();
    final List<CollectionStation> joinRows =
        await (select(collectionStations)
              ..orderBy(<OrderingTerm Function($CollectionStationsTable)>[
                ($CollectionStationsTable t) => OrderingTerm.asc(t.addedAt),
              ]))
            .get();

    final Map<String, List<String>> stationsByCollection =
        <String, List<String>>{};
    for (final CollectionStation join in joinRows) {
      stationsByCollection
          .putIfAbsent(join.collectionId, () => <String>[])
          .add(join.stationId);
    }

    return rows
        .map(
          (CollectionRow row) => Collection(
            id: row.id,
            title: row.title,
            subtitle: row.subtitle,
            isCurated: row.isCurated,
            updatedAt: row.updatedAt,
            stationIds: List<String>.unmodifiable(
              stationsByCollection[row.id] ?? const <String>[],
            ),
          ),
        )
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Song History
  // ---------------------------------------------------------------------------

  Future<void> insertSongHistory(SongHistoryEntry entry) async {
    await into(songHistoryEntries).insertOnConflictUpdate(
      SongHistoryEntriesCompanion(
        id: Value<String>(entry.id),
        stationId: Value<String>(entry.stationId),
        stationName: Value<String>(entry.stationName),
        trackTitle: Value<String>(entry.trackTitle),
        playedAt: Value<DateTime>(entry.playedAt),
      ),
    );
  }

  Future<List<SongHistoryEntry>> getSongHistory({int limit = 100}) async {
    final List<SongHistoryRow> rows =
        await (select(songHistoryEntries)
              ..orderBy(<OrderingTerm Function($SongHistoryEntriesTable)>[
                ($SongHistoryEntriesTable t) => OrderingTerm.desc(t.playedAt),
              ])
              ..limit(limit))
            .get();
    return rows
        .map(
          (SongHistoryRow row) => SongHistoryEntry(
            id: row.id,
            stationId: row.stationId,
            stationName: row.stationName,
            trackTitle: row.trackTitle,
            playedAt: row.playedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<void> clearSongHistory() async {
    await delete(songHistoryEntries).go();
  }

  // ---------------------------------------------------------------------------
  // User Settings (singleton row id = 1)
  // ---------------------------------------------------------------------------

  Future<UserSettings> getUserSettings() async {
    final UserSettingsTableData? row = await (select(
      userSettingsTable,
    )..where(($UserSettingsTableTable t) => t.id.equals(1))).getSingleOrNull();
    if (row == null) {
      return const UserSettings();
    }
    final List<dynamic> rawGenres =
        jsonDecode(row.preferredGenreIdsJson) as List<dynamic>;
    return UserSettings(
      dataSaver: row.dataSaver,
      defaultSleepMinutes: row.defaultSleepMinutes,
      theme: AppThemePreference.values.firstWhere(
        (AppThemePreference e) => e.name == row.theme,
        orElse: () => AppThemePreference.dark,
      ),
      languageCode: row.languageCode,
      notifyCollections: row.notifyCollections,
      workingNowDefault: row.workingNowDefault,
      homeCountryCode: row.homeCountryCode,
      preferredGenreIds: rawGenres.map((dynamic e) => e.toString()).toList(),
    );
  }

  Future<void> saveUserSettings(UserSettings settings) async {
    await into(userSettingsTable).insertOnConflictUpdate(
      UserSettingsTableCompanion(
        id: const Value<int>(1),
        dataSaver: Value<bool>(settings.dataSaver),
        defaultSleepMinutes: Value<int?>(settings.defaultSleepMinutes),
        theme: Value<String>(settings.theme.name),
        languageCode: Value<String>(settings.languageCode),
        notifyCollections: Value<bool>(settings.notifyCollections),
        workingNowDefault: Value<bool>(settings.workingNowDefault),
        homeCountryCode: Value<String?>(settings.homeCountryCode),
        preferredGenreIdsJson: Value<String>(
          jsonEncode(settings.preferredGenreIds),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private Mappers
  // ---------------------------------------------------------------------------

  static CachedStationsCompanion _stationToCompanion(
    Station s,
    DateTime updatedAt,
  ) {
    final List<Map<String, dynamic>> genresPayload = s.genres
        .map(
          (Genre g) => <String, dynamic>{
            'id': g.id,
            'name': g.name,
            'stationCount': g.stationCount,
            'tagline': g.tagline,
          },
        )
        .toList(growable: false);

    return CachedStationsCompanion(
      id: Value<String>(s.id),
      name: Value<String>(s.name),
      streamUrl: Value<String>(s.streamUrl),
      homepage: Value<String>(s.homepage),
      faviconUrl: Value<String?>(s.faviconUrl),
      usesFallbackLogo: Value<bool>(s.usesFallbackLogo),
      isHttps: Value<bool>(s.isHttps),
      isHls: Value<bool>(s.isHls),
      isWorking: Value<bool>(s.isWorking),
      countryCode: Value<String>(s.countryCode),
      countryName: Value<String>(s.countryName),
      genresJson: Value<String>(jsonEncode(genresPayload)),
      language: Value<String>(s.language),
      codec: Value<String>(s.codec),
      bitrateKbps: Value<int>(s.bitrateKbps),
      votes: Value<int>(s.votes),
      clickCount: Value<int>(s.clickCount),
      clickTrend: Value<int>(s.clickTrend),
      geoLat: Value<double?>(s.geoLat),
      geoLong: Value<double?>(s.geoLong),
      updatedAt: Value<DateTime>(updatedAt),
    );
  }

  static Station _stationFromRow(CachedStation row) {
    final List<dynamic> decodedGenres =
        jsonDecode(row.genresJson) as List<dynamic>;
    final List<Genre> genres = decodedGenres
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> g) => Genre(
            id: g['id'] as String? ?? '',
            name: g['name'] as String? ?? '',
            stationCount: (g['stationCount'] as num?)?.toInt() ?? 0,
            tagline: g['tagline'] as String? ?? '',
          ),
        )
        .where((Genre g) => g.id.isNotEmpty)
        .toList(growable: false);

    return Station(
      id: row.id,
      name: row.name,
      streamUrl: row.streamUrl,
      homepage: row.homepage,
      faviconUrl: row.faviconUrl,
      usesFallbackLogo: row.usesFallbackLogo,
      isHttps: row.isHttps,
      isHls: row.isHls,
      isWorking: row.isWorking,
      countryCode: row.countryCode,
      countryName: row.countryName,
      genres: genres,
      language: row.language,
      codec: row.codec,
      bitrateKbps: row.bitrateKbps,
      votes: row.votes,
      clickCount: row.clickCount,
      clickTrend: row.clickTrend,
      geoLat: row.geoLat,
      geoLong: row.geoLong,
    );
  }
}
