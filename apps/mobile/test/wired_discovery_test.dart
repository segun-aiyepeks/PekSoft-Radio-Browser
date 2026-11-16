import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/catalog_repository.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/explore/presentation/country_detail_screen.dart';
import 'package:peksoft_radio/features/explore/presentation/explore_screen.dart';
import 'package:peksoft_radio/features/explore/presentation/genre_detail_screen.dart';
import 'package:peksoft_radio/features/home/presentation/home_screen.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/library_repository.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/onboarding/presentation/welcome_screen.dart';
import 'package:peksoft_radio/features/profile/domain/settings_repository.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/search/presentation/search_screen.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/domain/station_repository.dart';
import 'package:peksoft_radio/features/station/presentation/station_detail_screen.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';

const Station _lagosStation = Station(
  id: 'ng-1',
  name: 'Cool FM Lagos',
  streamUrl: 'https://stream.example.com/cool',
  countryCode: 'NG',
  countryName: 'Nigeria',
  language: 'English',
  codec: 'MP3',
  bitrateKbps: 128,
  isHttps: true,
  isWorking: true,
  genres: <Genre>[Genre(id: 'afrobeats', name: 'Afrobeats')],
);

class _FakeCatalogRepo implements CatalogRepository {
  bool shouldFail = false;
  bool returnEmpty = false;
  Completer<List<Station>>? pendingTop;

  @override
  Future<Result<List<Country>>> getCountries({
    bool forceRefresh = false,
  }) async {
    if (shouldFail) {
      return const Failure<List<Country>>(
        AppFailure.network(message: 'Offline'),
      );
    }
    return const Success<List<Country>>(<Country>[
      Country(code: 'NG', name: 'Nigeria', stationCount: 75),
    ]);
  }

  @override
  Future<Result<List<Genre>>> getGenres({bool forceRefresh = false}) async =>
      const Success<List<Genre>>(<Genre>[
        Genre(
          id: 'afrobeats',
          name: 'Afrobeats',
          stationCount: 18,
          tagline: 'Lagos & Accra rhythms',
        ),
      ]);

  @override
  Future<Result<List<Language>>> getLanguages({
    bool forceRefresh = false,
  }) async => const Success<List<Language>>(<Language>[
    Language(code: 'en', name: 'English', stationCount: 100),
  ]);

  @override
  Future<Result<List<Station>>> getTopStations({
    int limit = 100,
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    if (pendingTop != null) {
      return Success<List<Station>>(await pendingTop!.future);
    }
    if (shouldFail) {
      return const Failure<List<Station>>(
        AppFailure.network(message: 'Network unreachable'),
      );
    }
    if (returnEmpty) return const Success<List<Station>>(<Station>[]);
    return const Success<List<Station>>(<Station>[_lagosStation]);
  }

  @override
  Future<Result<List<Station>>> getStationsByCountry(
    String countryCode, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    if (shouldFail) {
      return const Failure<List<Station>>(
        AppFailure.network(message: 'Country fetch failed'),
      );
    }
    if (returnEmpty) return const Success<List<Station>>(<Station>[]);
    return const Success<List<Station>>(<Station>[_lagosStation]);
  }

  @override
  Future<Result<List<Station>>> getStationsByGenre(
    String genreId, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    if (returnEmpty) return const Success<List<Station>>(<Station>[]);
    return const Success<List<Station>>(<Station>[_lagosStation]);
  }

  @override
  Future<Result<List<Station>>> searchStations(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    if (shouldFail) {
      return const Failure<List<Station>>(
        AppFailure.network(message: 'Search offline'),
      );
    }
    if ((filter.query ?? '').toLowerCase().contains('missing')) {
      return const Success<List<Station>>(<Station>[]);
    }
    return const Success<List<Station>>(<Station>[_lagosStation]);
  }
}

class _FakeStationRepo implements StationRepository {
  @override
  Future<Result<Station>> getStationById(String id) async =>
      const Success<Station>(_lagosStation);

  @override
  Future<Result<List<Station>>> getSimilarStations(
    Station station, {
    int limit = 10,
  }) async => const Success<List<Station>>(<Station>[]);

  @override
  Future<Result<void>> reportClick(String stationId) async =>
      const Success<void>(null);
}

class _FakeLibraryRepo implements LibraryRepository {
  final List<Station> favs = <Station>[];

  @override
  Future<Result<void>> addFavourite(Station station) async {
    favs.add(station);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> clearSongHistory() async => const Success<void>(null);

  @override
  Future<Result<void>> deleteCollection(String collectionId) async =>
      const Success<void>(null);

  @override
  Future<Result<List<Collection>>> getCollections() async =>
      const Success<List<Collection>>(<Collection>[
        Collection(
          id: 'curated-1',
          title: 'Lagos Morning',
          subtitle: 'News & Afrobeats',
          stationIds: <String>['ng-1'],
          isCurated: true,
        ),
      ]);

  @override
  Future<Result<List<Station>>> getFavourites() async =>
      Success<List<Station>>(List<Station>.unmodifiable(favs));

  @override
  Future<Result<List<Station>>> getRecents({int limit = 50}) async =>
      const Success<List<Station>>(<Station>[]);

  @override
  Future<Result<List<SongHistoryEntry>>> getSongHistory({
    int limit = 100,
  }) async => const Success<List<SongHistoryEntry>>(<SongHistoryEntry>[]);

  @override
  Future<Result<bool>> isFavourite(String stationId) async =>
      Success<bool>(favs.any((Station s) => s.id == stationId));

  @override
  Future<Result<void>> logSongHistory(SongHistoryEntry entry) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> recordRecent(Station station) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> removeFavourite(String stationId) async {
    favs.removeWhere((Station s) => s.id == stationId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveCollection(Collection collection) async =>
      const Success<void>(null);
}

class _FakeSettingsRepo implements SettingsRepository {
  UserSettings settings = const UserSettings();

  @override
  Future<Result<UserSettings>> getSettings() async =>
      Success<UserSettings>(settings);

  @override
  Future<Result<void>> saveSettings(UserSettings next) async {
    settings = next;
    return const Success<void>(null);
  }
}

Widget _wrapWithProviders(
  Widget child, {
  required _FakeCatalogRepo catalog,
  _FakeStationRepo? stationRepo,
  _FakeLibraryRepo? libraryRepo,
  _FakeSettingsRepo? settingsRepo,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      catalogRepositoryProvider.overrideWithValue(catalog),
      stationRepositoryProvider.overrideWithValue(
        stationRepo ?? _FakeStationRepo(),
      ),
      libraryRepositoryProvider.overrideWithValue(
        libraryRepo ?? _FakeLibraryRepo(),
      ),
      settingsRepositoryProvider.overrideWithValue(
        settingsRepo ?? _FakeSettingsRepo(),
      ),
      entitlementRepositoryProvider.overrideWithValue(
        const EntitlementRepositoryImpl(),
      ),
    ],
    child: MaterialApp(theme: AppTheme.dark(), home: child),
  );
}

void main() {
  group('Milestone 3.1 Wired Discovery Screens', () {
    testWidgets(
      'HomeScreen shows SkeletonList, loaded data, empty, and error',
      (tester) async {
        final _FakeCatalogRepo catalog = _FakeCatalogRepo()
          ..pendingTop = Completer<List<Station>>();

        await tester.pumpWidget(
          _wrapWithProviders(const HomeScreen(), catalog: catalog),
        );
        expect(find.byType(SkeletonList), findsOneWidget);

        catalog.pendingTop!.complete(<Station>[_lagosStation]);
        catalog.pendingTop = null;
        await tester.pumpAndSettle();

        expect(find.text('Cool FM Lagos'), findsOneWidget);
        expect(find.text('Lagos Morning'), findsOneWidget);
        expect(find.byType(AdSlotPlaceholder), findsOneWidget);

        // Error state + retry
        catalog.shouldFail = true;
        await tester.pumpWidget(
          _wrapWithProviders(const HomeScreen(), catalog: catalog),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ErrorState), findsOneWidget);

        catalog.shouldFail = false;
        catalog.returnEmpty = true;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(find.byType(EmptyState), findsOneWidget);
      },
    );

    testWidgets('ExploreScreen renders Countries, Genres, Languages, and Map', (
      tester,
    ) async {
      final _FakeCatalogRepo catalog = _FakeCatalogRepo();
      await tester.pumpWidget(
        _wrapWithProviders(const ExploreScreen(), catalog: catalog),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nigeria'), findsOneWidget);

      await tester.tap(find.text('Genres'));
      await tester.pumpAndSettle();
      expect(find.text('Afrobeats'), findsOneWidget);

      await tester.tap(find.text('Languages'));
      await tester.pumpAndSettle();
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();
      expect(find.text('World Radio Map (Placeholder)'), findsOneWidget);
    });

    testWidgets('SearchScreen shows idle, results, no-results, and Filters', (
      tester,
    ) async {
      final _FakeCatalogRepo catalog = _FakeCatalogRepo();
      await tester.pumpWidget(
        _wrapWithProviders(const SearchScreen(), catalog: catalog),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try searching for'), findsOneWidget);

      await tester.tap(find.text('Wazobia'));
      await tester.pumpAndSettle();
      expect(find.text('Cool FM Lagos'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'missing');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('No stations found'), findsOneWidget);

      // Filters bottom sheet has Working now ON by default.
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Working now only'), findsOneWidget);
      final Switch workingSwitch = tester.widget<Switch>(find.byType(Switch));
      expect(workingSwitch.value, isTrue);
    });

    testWidgets('CountryDetail, GenreDetail, StationDetail, and Welcome', (
      tester,
    ) async {
      final _FakeCatalogRepo catalog = _FakeCatalogRepo();
      final _FakeLibraryRepo library = _FakeLibraryRepo();

      await tester.pumpWidget(
        _wrapWithProviders(
          const CountryDetailScreen(countryCode: 'NG'),
          catalog: catalog,
          libraryRepo: library,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cool FM Lagos'), findsOneWidget);

      await tester.pumpWidget(
        _wrapWithProviders(
          const GenreDetailScreen(genreName: 'Afrobeats'),
          catalog: catalog,
          libraryRepo: library,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cool FM Lagos'), findsOneWidget);

      await tester.pumpWidget(
        _wrapWithProviders(
          const StationDetailScreen(stationId: 'ng-1'),
          catalog: catalog,
          libraryRepo: library,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Play Station'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.pumpWidget(
        _wrapWithProviders(const WelcomeScreen(), catalog: catalog),
      );
      await tester.pumpAndSettle();
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Tune into your world'), findsOneWidget);
    });
  });
}
