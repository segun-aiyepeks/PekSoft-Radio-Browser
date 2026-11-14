import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:peksoft_radio/features/catalog/domain/catalog_repository.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/country_detail_view_model.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/explore_view_model.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/genre_detail_view_model.dart';
import 'package:peksoft_radio/features/home/presentation/view_models/home_view_model.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/domain/library_repository.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/onboarding/presentation/view_models/splash_view_model.dart';
import 'package:peksoft_radio/features/onboarding/presentation/view_models/welcome_view_model.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/profile/domain/settings_repository.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/profile/presentation/view_models/settings_view_model.dart';
import 'package:peksoft_radio/features/search/presentation/view_models/search_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/domain/station_repository.dart';
import 'package:peksoft_radio/features/station/presentation/view_models/station_detail_view_model.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/presentation/view_models/subscription_view_model.dart';

import 'helpers/fake_audio_player_service.dart';
import 'helpers/fake_connectivity_service.dart';
import 'helpers/fake_report_queue_repository.dart';

const Station _sampleStation = Station(
  id: 'st-1',
  name: 'Cool FM Lagos',
  streamUrl: 'https://stream.example.com/cool',
  countryCode: 'NG',
  countryName: 'Nigeria',
  isHttps: true,
  isWorking: true,
  genres: <Genre>[Genre(id: 'afrobeats', name: 'Afrobeats')],
);

const Station _otherStation = Station(
  id: 'st-2',
  name: 'BBC Radio 1',
  streamUrl: 'https://stream.example.com/bbc1',
  countryCode: 'GB',
  countryName: 'United Kingdom',
  isHttps: true,
  isWorking: true,
  genres: <Genre>[Genre(id: 'pop', name: 'Pop')],
);

class _FakeCatalogRepo implements CatalogRepository {
  @override
  Future<Result<List<Country>>> getCountries({
    bool forceRefresh = false,
  }) async => const Success<List<Country>>(<Country>[
    Country(code: 'NG', name: 'Nigeria', stationCount: 75),
  ]);

  @override
  Future<Result<List<Genre>>> getGenres({bool forceRefresh = false}) async =>
      const Success<List<Genre>>(<Genre>[
        Genre(id: 'afrobeats', name: 'Afrobeats', stationCount: 18),
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
  }) async => const Success<List<Station>>(<Station>[_sampleStation]);

  @override
  Future<Result<List<Station>>> getStationsByCountry(
    String countryCode, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async => const Success<List<Station>>(<Station>[_sampleStation]);

  @override
  Future<Result<List<Station>>> getStationsByGenre(
    String genreId, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async => const Success<List<Station>>(<Station>[_sampleStation]);

  @override
  Future<Result<List<Station>>> searchStations(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    if ((filter.query ?? '').toLowerCase().contains('bbc')) {
      return const Success<List<Station>>(<Station>[_otherStation]);
    }
    return const Success<List<Station>>(<Station>[_sampleStation]);
  }
}

class _FakeStationRepo implements StationRepository {
  bool clickReported = false;

  @override
  Future<Result<Station>> getStationById(String id) async =>
      const Success<Station>(_sampleStation);

  @override
  Future<Result<List<Station>>> getSimilarStations(
    Station station, {
    int limit = 10,
  }) async => const Success<List<Station>>(<Station>[_otherStation]);

  @override
  Future<Result<void>> reportClick(String stationId) async {
    clickReported = true;
    return const Success<void>(null);
  }
}

class _FakeLibraryRepo implements LibraryRepository {
  final List<Station> favs = <Station>[];
  final List<Station> recents = <Station>[];
  final List<Collection> collections = <Collection>[
    const Collection(id: 'curated-1', title: 'Lagos Morning', isCurated: true),
  ];
  final List<SongHistoryEntry> history = <SongHistoryEntry>[];

  @override
  Future<Result<void>> addFavourite(Station station) async {
    if (!favs.any((Station s) => s.id == station.id)) {
      favs.add(station);
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> clearSongHistory() async {
    history.clear();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteCollection(String collectionId) async {
    collections.removeWhere((Collection c) => c.id == collectionId);
    return const Success<void>(null);
  }

  @override
  Future<Result<List<Collection>>> getCollections() async =>
      Success<List<Collection>>(List<Collection>.unmodifiable(collections));

  @override
  Future<Result<List<Station>>> getFavourites() async =>
      Success<List<Station>>(List<Station>.unmodifiable(favs));

  @override
  Future<Result<List<Station>>> getRecents({int limit = 50}) async =>
      Success<List<Station>>(List<Station>.unmodifiable(recents));

  @override
  Future<Result<List<SongHistoryEntry>>> getSongHistory({
    int limit = 100,
  }) async => Success<List<SongHistoryEntry>>(
    List<SongHistoryEntry>.unmodifiable(history),
  );

  @override
  Future<Result<bool>> isFavourite(String stationId) async =>
      Success<bool>(favs.any((Station s) => s.id == stationId));

  @override
  Future<Result<void>> logSongHistory(SongHistoryEntry entry) async {
    history.add(entry);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> recordRecent(Station station) async {
    recents.add(station);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> removeFavourite(String stationId) async {
    favs.removeWhere((Station s) => s.id == stationId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> saveCollection(Collection collection) async {
    collections.add(collection);
    return const Success<void>(null);
  }
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

ProviderContainer _createContainer({
  _FakeStationRepo? stationRepo,
  _FakeLibraryRepo? libraryRepo,
  _FakeSettingsRepo? settingsRepo,
}) {
  return ProviderContainer(
    overrides: [
      catalogRepositoryProvider.overrideWithValue(_FakeCatalogRepo()),
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
      audioPlayerServiceProvider.overrideWithValue(FakeAudioPlayerService()),
      connectivityServiceProvider.overrideWithValue(FakeConnectivityService()),
      reportQueueRepositoryProvider.overrideWithValue(
        FakeReportQueueRepository(),
      ),
      playbackRetryDelaysProvider.overrideWithValue(const <Duration>[
        Duration.zero,
        Duration.zero,
        Duration.zero,
      ]),
    ],
  );
}

void main() {
  group('Milestone 2.6 ViewModels', () {
    test('SplashViewModel routes based on saved homeCountryCode', () async {
      final _FakeSettingsRepo settings = _FakeSettingsRepo();
      final ProviderContainer c1 = _createContainer(settingsRepo: settings);
      addTearDown(c1.dispose);
      final SplashState s1 = await c1.read(splashViewModelProvider.future);
      expect(s1.isInitialized, isTrue);
      expect(s1.destinationRoute, '/welcome');

      settings.settings = const UserSettings(homeCountryCode: 'NG');
      final ProviderContainer c2 = _createContainer(settingsRepo: settings);
      addTearDown(c2.dispose);
      final SplashState s2 = await c2.read(splashViewModelProvider.future);
      expect(s2.destinationRoute, '/home');
    });

    test(
      'WelcomeViewModel selects country, toggles genres, and saves',
      () async {
        final _FakeSettingsRepo settings = _FakeSettingsRepo();
        final ProviderContainer container = _createContainer(
          settingsRepo: settings,
        );
        addTearDown(container.dispose);

        final WelcomeViewModel vm = container.read(
          welcomeViewModelProvider.notifier,
        );
        vm.selectCountry('ng');
        vm.toggleGenre('afrobeats');
        vm.toggleGenre('jazz');
        vm.toggleGenre('jazz');
        await vm.completeOnboarding();

        final WelcomeState state = container.read(welcomeViewModelProvider);
        expect(state.completed, isTrue);
        expect(settings.settings.homeCountryCode, 'NG');
        expect(settings.settings.preferredGenreIds, <String>['afrobeats']);
      },
    );

    test(
      'HomeViewModel & ExploreViewModel load data and switch tabs/genres',
      () async {
        final ProviderContainer container = _createContainer();
        addTearDown(container.dispose);

        final HomeState home = await container.read(
          homeViewModelProvider.future,
        );
        expect(home.stations, <Station>[_sampleStation]);
        expect(home.curatedCollections.length, 1);

        await container
            .read(homeViewModelProvider.notifier)
            .selectGenre('afrobeats');
        expect(
          container.read(homeViewModelProvider).requireValue.selectedGenreId,
          'afrobeats',
        );

        final ExploreState explore = await container.read(
          exploreViewModelProvider.future,
        );
        expect(explore.countries.length, 1);
        expect(explore.genres.length, 1);
        expect(explore.languages.length, 1);

        container.read(exploreViewModelProvider.notifier).selectTab(2);
        expect(
          container.read(exploreViewModelProvider).requireValue.activeTabIndex,
          2,
        );
      },
    );

    test(
      'CountryDetail, GenreDetail, Search, and StationDetail ViewModels',
      () async {
        final ProviderContainer container = _createContainer();
        addTearDown(container.dispose);

        final CountryDetailState countryState = await container.read(
          countryDetailViewModelProvider('NG').future,
        );
        expect(countryState.stations.length, 1);
        await container
            .read(countryDetailViewModelProvider('NG').notifier)
            .toggleWorkingNow();
        expect(
          container
              .read(countryDetailViewModelProvider('NG'))
              .requireValue
              .workingNowOnly,
          isFalse,
        );

        final GenreDetailState genreState = await container.read(
          genreDetailViewModelProvider('afrobeats').future,
        );
        expect(genreState.stations.length, 1);

        final SearchViewModel searchVm = container.read(
          searchViewModelProvider.notifier,
        );
        searchVm.setQuery('BBC');
        await searchVm.submitSearch();
        final SearchState searchState = container.read(searchViewModelProvider);
        expect(searchState.results, <Station>[_otherStation]);
        expect(searchState.recentQueries, <String>['BBC']);

        final StationDetailState detail = await container.read(
          stationDetailViewModelProvider('st-1').future,
        );
        expect(detail.station, _sampleStation);
        expect(detail.isFavourite, isFalse);
        await container
            .read(stationDetailViewModelProvider('st-1').notifier)
            .toggleFavourite();
        expect(
          container
              .read(stationDetailViewModelProvider('st-1'))
              .requireValue
              .isFavourite,
          isTrue,
        );
      },
    );

    test(
      'PlayerViewModel plays station, logs track & sleep timer, and reports',
      () async {
        final _FakeStationRepo stationRepo = _FakeStationRepo();
        final _FakeLibraryRepo libraryRepo = _FakeLibraryRepo();
        final ProviderContainer container = _createContainer(
          stationRepo: stationRepo,
          libraryRepo: libraryRepo,
        );
        addTearDown(container.dispose);

        final PlayerViewModel player = container.read(
          playerViewModelProvider.notifier,
        );
        await player.playStation(_sampleStation);
        expect(stationRepo.clickReported, isTrue);
        expect(libraryRepo.recents, <Station>[_sampleStation]);
        expect(
          container.read(playerViewModelProvider).playback.status,
          PlaybackStatus.playing,
        );

        player.togglePlayPause();
        expect(
          container.read(playerViewModelProvider).playback.status,
          PlaybackStatus.paused,
        );

        await player.updateTrackTitle('Wizkid - Essence');
        expect(libraryRepo.history.length, 1);

        player.setSleepTimer(const Duration(minutes: 15));
        expect(
          container.read(playerViewModelProvider).playback.sleepTimerRemaining,
          const Duration(minutes: 15),
        );
        player.reportCurrentStation('Stream offline');
        expect(container.read(playerViewModelProvider).reportSubmitted, isTrue);
      },
    );

    test('Library, Auth, Subscription, and Settings ViewModels', () async {
      final _FakeLibraryRepo libraryRepo = _FakeLibraryRepo();
      final ProviderContainer container = _createContainer(
        libraryRepo: libraryRepo,
      );
      addTearDown(container.dispose);

      await container.read(libraryViewModelProvider.future);
      await container
          .read(libraryViewModelProvider.notifier)
          .createCollection('Workout Mix');
      expect(
        container
            .read(libraryViewModelProvider)
            .requireValue
            .collections
            .any((Collection c) => c.title == 'Workout Mix'),
        isTrue,
      );

      final AuthViewModel auth = container.read(authViewModelProvider.notifier);
      auth.signInWithEmail('bad-email', '123');
      expect(
        container.read(authViewModelProvider).error,
        isA<ValidationFailure>(),
      );
      auth.signInWithEmail('user@peksoft.dev', 'secret123');
      expect(container.read(authViewModelProvider).isAuthenticated, isTrue);

      final SubscriptionState sub = await container.read(
        subscriptionViewModelProvider.future,
      );
      expect(sub.entitlement.tier, EntitlementTier.free);
      container
          .read(subscriptionViewModelProvider.notifier)
          .selectBillingPeriod(BillingPeriod.monthly);
      await container
          .read(subscriptionViewModelProvider.notifier)
          .restorePurchases();
      expect(
        container
            .read(subscriptionViewModelProvider)
            .requireValue
            .billingPeriod,
        BillingPeriod.monthly,
      );

      await container.read(settingsViewModelProvider.future);
      await container
          .read(settingsViewModelProvider.notifier)
          .toggleDataSaver(true);
      await container
          .read(settingsViewModelProvider.notifier)
          .setTheme(AppThemePreference.light);
      final SettingsState settingsState = container
          .read(settingsViewModelProvider)
          .requireValue;
      expect(settingsState.settings.dataSaver, isTrue);
      expect(settingsState.settings.theme, AppThemePreference.light);
    });
  });
}
