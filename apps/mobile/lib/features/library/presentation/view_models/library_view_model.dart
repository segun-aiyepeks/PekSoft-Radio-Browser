import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

/// Immutable state for [LibraryScreen] (`/library`).
@immutable
class LibraryState {
  const LibraryState({
    this.activeTabIndex = 0,
    this.favourites = const <Station>[],
    this.recents = const <Station>[],
    this.collections = const <Collection>[],
    this.songHistory = const <SongHistoryEntry>[],
    this.entitlement = const Entitlement(),
    this.limitReachedFailure,
    this.error,
  });

  final int activeTabIndex;
  final List<Station> favourites;
  final List<Station> recents;
  final List<Collection> collections;
  final List<SongHistoryEntry> songHistory;
  final Entitlement entitlement;
  final EntitlementRequiredFailure? limitReachedFailure;
  final AppFailure? error;

  LibraryState copyWith({
    int? activeTabIndex,
    List<Station>? favourites,
    List<Station>? recents,
    List<Collection>? collections,
    List<SongHistoryEntry>? songHistory,
    Entitlement? entitlement,
    EntitlementRequiredFailure? limitReachedFailure,
    bool clearLimitFailure = false,
    AppFailure? error,
    bool clearError = false,
  }) {
    return LibraryState(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      favourites: favourites ?? this.favourites,
      recents: recents ?? this.recents,
      collections: collections ?? this.collections,
      songHistory: songHistory ?? this.songHistory,
      entitlement: entitlement ?? this.entitlement,
      limitReachedFailure: clearLimitFailure
          ? null
          : (limitReachedFailure ?? this.limitReachedFailure),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for [LibraryScreen] (`/library`).
class LibraryViewModel extends AsyncNotifier<LibraryState> {
  @override
  Future<LibraryState> build() => _load();

  void selectTab(int index) {
    final LibraryState? current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue<LibraryState>.data(
      current.copyWith(activeTabIndex: index),
    );
  }

  Future<void> toggleFavourite(Station station) async {
    final LibraryState current = state.asData?.value ?? const LibraryState();
    final library = ref.read(libraryRepositoryProvider);
    final bool exists = current.favourites.any(
      (Station s) => s.id == station.id,
    );
    final Result<void> res = exists
        ? await library.removeFavourite(station.id)
        : await library.addFavourite(station);

    switch (res) {
      case Success<void>():
        state = AsyncValue<LibraryState>.data(
          await _load(activeTabIndex: current.activeTabIndex),
        );
      case Failure<void>(:final error):
        if (error is EntitlementRequiredFailure) {
          state = AsyncValue<LibraryState>.data(
            current.copyWith(limitReachedFailure: error),
          );
        } else {
          state = AsyncValue<LibraryState>.data(current.copyWith(error: error));
        }
    }
  }

  Future<void> createCollection(String title, {String subtitle = ''}) async {
    final LibraryState current = state.asData?.value ?? const LibraryState();
    final String cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return;

    final Collection collection = Collection(
      id: 'col-${DateTime.now().microsecondsSinceEpoch}',
      title: cleanTitle,
      subtitle: subtitle.trim(),
      updatedAt: DateTime.now(),
    );
    final Result<void> res = await ref
        .read(libraryRepositoryProvider)
        .saveCollection(collection);

    switch (res) {
      case Success<void>():
        state = AsyncValue<LibraryState>.data(
          await _load(activeTabIndex: current.activeTabIndex),
        );
      case Failure<void>(:final error):
        if (error is EntitlementRequiredFailure) {
          state = AsyncValue<LibraryState>.data(
            current.copyWith(limitReachedFailure: error),
          );
        } else {
          state = AsyncValue<LibraryState>.data(current.copyWith(error: error));
        }
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    final int tab = state.asData?.value.activeTabIndex ?? 0;
    await ref.read(libraryRepositoryProvider).deleteCollection(collectionId);
    state = AsyncValue<LibraryState>.data(await _load(activeTabIndex: tab));
  }

  Future<void> clearSongHistory() async {
    final int tab = state.asData?.value.activeTabIndex ?? 0;
    await ref.read(libraryRepositoryProvider).clearSongHistory();
    state = AsyncValue<LibraryState>.data(await _load(activeTabIndex: tab));
  }

  void clearLimitPrompt() {
    final LibraryState? current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue<LibraryState>.data(
      current.copyWith(clearLimitFailure: true),
    );
  }

  Future<void> refresh() async {
    final int tab = state.asData?.value.activeTabIndex ?? 0;
    state = const AsyncValue<LibraryState>.loading();
    state = AsyncValue<LibraryState>.data(await _load(activeTabIndex: tab));
  }

  Future<LibraryState> _load({int activeTabIndex = 0}) async {
    final library = ref.read(libraryRepositoryProvider);
    final entitlementRepo = ref.read(entitlementRepositoryProvider);

    final favRes = await library.getFavourites();
    final recentsRes = await library.getRecents();
    final colRes = await library.getCollections();
    final historyRes = await library.getSongHistory();
    final entRes = await entitlementRepo.getEntitlement();

    return LibraryState(
      activeTabIndex: activeTabIndex,
      favourites: switch (favRes) {
        Success<List<Station>>(:final data) => data,
        Failure<List<Station>>() => const <Station>[],
      },
      recents: switch (recentsRes) {
        Success<List<Station>>(:final data) => data,
        Failure<List<Station>>() => const <Station>[],
      },
      collections: switch (colRes) {
        Success<List<Collection>>(:final data) => data,
        Failure<List<Collection>>() => const <Collection>[],
      },
      songHistory: switch (historyRes) {
        Success<List<SongHistoryEntry>>(:final data) => data,
        Failure<List<SongHistoryEntry>>() => const <SongHistoryEntry>[],
      },
      entitlement: switch (entRes) {
        Success<Entitlement>(:final data) => data,
        Failure<Entitlement>() => const Entitlement(),
      },
    );
  }
}

final AsyncNotifierProvider<LibraryViewModel, LibraryState>
libraryViewModelProvider =
    AsyncNotifierProvider<LibraryViewModel, LibraryState>(LibraryViewModel.new);
