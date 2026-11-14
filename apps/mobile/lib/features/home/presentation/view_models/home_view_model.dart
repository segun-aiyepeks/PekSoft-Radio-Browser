import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

/// Immutable state for the Home screen (`/home`).
@immutable
class HomeState {
  const HomeState({
    this.genres = const <Genre>[],
    this.curatedCollections = const <Collection>[],
    this.stations = const <Station>[],
    this.selectedGenreId,
    this.entitlement = const Entitlement(),
    this.error,
  });

  final List<Genre> genres;
  final List<Collection> curatedCollections;
  final List<Station> stations;
  final String? selectedGenreId;
  final Entitlement entitlement;
  final AppFailure? error;

  HomeState copyWith({
    List<Genre>? genres,
    List<Collection>? curatedCollections,
    List<Station>? stations,
    String? selectedGenreId,
    bool clearSelectedGenre = false,
    Entitlement? entitlement,
    AppFailure? error,
    bool clearError = false,
  }) {
    return HomeState(
      genres: genres ?? this.genres,
      curatedCollections: curatedCollections ?? this.curatedCollections,
      stations: stations ?? this.stations,
      selectedGenreId: clearSelectedGenre
          ? null
          : (selectedGenreId ?? this.selectedGenreId),
      entitlement: entitlement ?? this.entitlement,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for [HomeScreen] (`/home`).
class HomeViewModel extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() => _load(selectedGenreId: null);

  Future<void> refresh() async {
    final String? genreId = state.asData?.value.selectedGenreId;
    state = const AsyncValue<HomeState>.loading();
    state = AsyncValue<HomeState>.data(
      await _load(selectedGenreId: genreId, forceRefresh: true),
    );
  }

  Future<void> selectGenre(String? genreId) async {
    final HomeState previous = state.asData?.value ?? const HomeState();
    state = AsyncValue<HomeState>.data(
      await _load(
        selectedGenreId: genreId,
        cachedGenres: previous.genres,
        cachedCollections: previous.curatedCollections,
      ),
    );
  }

  Future<HomeState> _load({
    required String? selectedGenreId,
    List<Genre>? cachedGenres,
    List<Collection>? cachedCollections,
    bool forceRefresh = false,
  }) async {
    final catalog = ref.read(catalogRepositoryProvider);
    final library = ref.read(libraryRepositoryProvider);
    final entitlementRepo = ref.read(entitlementRepositoryProvider);

    final List<Genre> genres =
        cachedGenres ??
        switch (await catalog.getGenres()) {
          Success<List<Genre>>(:final data) => data,
          Failure<List<Genre>>() => const <Genre>[],
        };

    final List<Collection> collections =
        cachedCollections ??
        switch (await library.getCollections()) {
          Success<List<Collection>>(:final data) =>
            data.where((Collection c) => c.isCurated).toList(growable: false),
          Failure<List<Collection>>() => const <Collection>[],
        };

    final Entitlement entitlement = switch (await entitlementRepo
        .getEntitlement()) {
      Success<Entitlement>(:final data) => data,
      Failure<Entitlement>() => const Entitlement(),
    };

    final Result<List<Station>> stationsRes = selectedGenreId == null
        ? await catalog.getTopStations(forceRefresh: forceRefresh)
        : await catalog.getStationsByGenre(
            selectedGenreId,
            filter: StationFilter(genreId: selectedGenreId),
            forceRefresh: forceRefresh,
          );

    return switch (stationsRes) {
      Success<List<Station>>(:final data) => HomeState(
        genres: genres,
        curatedCollections: collections,
        stations: data,
        selectedGenreId: selectedGenreId,
        entitlement: entitlement,
      ),
      Failure<List<Station>>(:final error) => HomeState(
        genres: genres,
        curatedCollections: collections,
        stations: const <Station>[],
        selectedGenreId: selectedGenreId,
        entitlement: entitlement,
        error: error,
      ),
    };
  }
}

final AsyncNotifierProvider<HomeViewModel, HomeState> homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
