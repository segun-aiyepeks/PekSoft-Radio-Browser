import 'package:flutter_riverpod/misc.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/catalog/domain/catalog_repository.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/library_repository.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/profile/domain/settings_repository.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/domain/station_repository.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/mock/mock.dart';

import 'fake_audio_player_service.dart';

/// Converts Phase 1 mock data into fake Riverpod repository overrides for
/// widget and golden tests (zero network, zero SQLite).
List<Override> mockRepositoryOverrides({
  FakeAudioPlayerService? audioPlayerService,
}) {
  final _MockCatalogRepository catalog = _MockCatalogRepository();
  final _MockStationRepository station = _MockStationRepository();
  final _MockLibraryRepository library = _MockLibraryRepository();
  final _MockSettingsRepository settings = _MockSettingsRepository();
  final FakeAudioPlayerService audio =
      audioPlayerService ?? FakeAudioPlayerService();

  return <Override>[
    catalogRepositoryProvider.overrideWithValue(catalog),
    stationRepositoryProvider.overrideWithValue(station),
    libraryRepositoryProvider.overrideWithValue(library),
    settingsRepositoryProvider.overrideWithValue(settings),
    entitlementRepositoryProvider.overrideWithValue(
      const EntitlementRepositoryImpl(),
    ),
    audioPlayerServiceProvider.overrideWithValue(audio),
  ];
}

Station _toDomainStation(MockStation m) {
  return Station(
    id: m.id,
    name: m.name,
    streamUrl: 'https://stream.example.com/${m.id}',
    homepage: m.homepage,
    faviconUrl: m.faviconUrl,
    usesFallbackLogo: m.faviconUrl == null || m.faviconUrl!.isEmpty,
    isHttps: m.isHttps,
    isHls: m.isHls,
    isWorking: m.isWorking,
    countryCode: m.countryCode,
    countryName: m.country,
    genres: m.genres
        .map((String name) => Genre(id: _genreIdFromName(name), name: name))
        .toList(growable: false),
    language: m.language,
    codec: m.codec,
    bitrateKbps: m.bitrateKbps,
    votes: m.votes,
    clickCount: m.clickCount,
    clickTrend: 0,
  );
}

String _genreIdFromName(String name) {
  final String lower = name.trim().toLowerCase();
  for (final MockGenre g in getMockGenres()) {
    if (g.id == lower || g.name.toLowerCase() == lower) {
      return g.id;
    }
  }
  if (lower == 'news') return 'news';
  if (lower == 'lo-fi') return 'lounge';
  if (lower == 'electronic') return 'electronic';
  return lower.replaceAll(' ', '-');
}

class _MockCatalogRepository implements CatalogRepository {
  @override
  Future<Result<List<Country>>> getCountries({
    bool forceRefresh = false,
  }) async {
    return Success<List<Country>>(
      getMockCountries()
          .map(
            (MockCountry c) => Country(
              code: c.code,
              name: c.name,
              stationCount: c.stationCount,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Genre>>> getGenres({bool forceRefresh = false}) async {
    return Success<List<Genre>>(
      getMockGenres()
          .map(
            (MockGenre g) => Genre(
              id: g.id,
              name: g.name,
              stationCount: g.stationCount,
              tagline: g.tagline,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Language>>> getLanguages({
    bool forceRefresh = false,
  }) async {
    return Success<List<Language>>(
      getMockLanguages()
          .map(
            (MockLanguage l) => Language(
              code: l.code,
              name: l.name,
              stationCount: l.stationCount,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Station>>> getTopStations({
    int limit = 100,
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    return searchStations(filter, sort: sort);
  }

  @override
  Future<Result<List<Station>>> getStationsByCountry(
    String countryCode, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    final List<Station> list = getMockStationsByCountry(
      countryCode,
      workingOnly: filter.workingNowOnly,
    ).map(_toDomainStation).toList(growable: false);
    return Success<List<Station>>(list);
  }

  @override
  Future<Result<List<Station>>> getStationsByGenre(
    String genreId, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    final List<Station> all = getMockStations()
        .map(_toDomainStation)
        .where((Station s) {
          if (filter.workingNowOnly && !s.isWorking) return false;
          return s.genres.any(
            (Genre g) =>
                g.id == genreId.toLowerCase() ||
                g.name.toLowerCase() == genreId.toLowerCase(),
          );
        })
        .toList(growable: false);
    return Success<List<Station>>(all);
  }

  @override
  Future<Result<List<Station>>> searchStations(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    final MockStationSort mockSort = switch (sort) {
      StationSortOption.popular => MockStationSort.popular,
      StationSortOption.trending => MockStationSort.popular,
      StationSortOption.votes => MockStationSort.votes,
      StationSortOption.bitrate => MockStationSort.bitrate,
      StationSortOption.nameAsc => MockStationSort.name,
    };
    final List<Station> results = searchMockStations(
      query: filter.query ?? '',
      workingOnly: filter.workingNowOnly,
      genre: filter.genreId,
      language: filter.language,
      codec: filter.codec,
      minBitrateKbps: filter.minBitrateKbps,
      sort: mockSort,
    ).map(_toDomainStation).toList(growable: false);
    return Success<List<Station>>(results);
  }
}

class _MockStationRepository implements StationRepository {
  @override
  Future<Result<Station>> getStationById(String id) async {
    final MockStation? found = getMockStationById(id);
    if (found == null) {
      return Failure<Station>(
        AppFailure.notFound(message: 'Station $id not found'),
      );
    }
    return Success<Station>(_toDomainStation(found));
  }

  @override
  Future<Result<List<Station>>> getSimilarStations(
    Station station, {
    int limit = 10,
  }) async {
    final MockStation? found = getMockStationById(station.id);
    if (found == null) return const Success<List<Station>>(<Station>[]);
    return Success<List<Station>>(
      getMockSimilarStations(
        found,
      ).map(_toDomainStation).toList(growable: false),
    );
  }

  @override
  Future<Result<void>> reportClick(String stationId) async =>
      const Success<void>(null);
}

class _MockLibraryRepository implements LibraryRepository {
  final List<Station> _favs = <Station>[];
  final List<Station> _recents = <Station>[];
  final List<SongHistoryEntry> _history = <SongHistoryEntry>[];

  @override
  Future<Result<void>> addFavourite(Station station) async {
    _favs.add(station);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> clearSongHistory() async {
    _history.clear();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) async =>
      const Success<void>(null);

  @override
  Future<Result<List<Collection>>> getCollections() async {
    return Success<List<Collection>>(
      getMockCuratedCollections()
          .map(
            (MockCuratedCollection c) => Collection(
              id: c.id,
              title: c.title,
              subtitle: c.subtitle,
              stationIds: c.stationIds,
              isCurated: true,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<Result<List<Station>>> getFavourites() async =>
      Success<List<Station>>(List<Station>.unmodifiable(_favs));

  @override
  Future<Result<List<Station>>> getRecents({int limit = 50}) async =>
      Success<List<Station>>(List<Station>.unmodifiable(_recents.take(limit)));

  @override
  Future<Result<List<SongHistoryEntry>>> getSongHistory({
    int limit = 100,
  }) async => Success<List<SongHistoryEntry>>(
    List<SongHistoryEntry>.unmodifiable(_history.take(limit)),
  );

  @override
  Future<Result<bool>> isFavourite(String stationId) async =>
      Success<bool>(_favs.any((Station s) => s.id == stationId));

  @override
  Future<Result<void>> logSongHistory(SongHistoryEntry entry) async {
    _history.insert(0, entry);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> recordRecent(Station station) async {
    _recents.removeWhere((Station s) => s.id == station.id);
    _recents.insert(0, station);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> removeFavourite(String stationId) async {
    _favs.removeWhere((Station s) => s.id == stationId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveCollection(Collection collection) async =>
      const Success<void>(null);
}

class _MockSettingsRepository implements SettingsRepository {
  UserSettings _settings = const UserSettings();

  @override
  Future<Result<UserSettings>> getSettings() async =>
      Success<UserSettings>(_settings);

  @override
  Future<Result<void>> saveSettings(UserSettings settings) async {
    _settings = settings;
    return const Success<void>(null);
  }
}
