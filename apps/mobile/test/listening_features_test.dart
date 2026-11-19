import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/features/catalog/domain/catalog_repository.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/home/presentation/home_screen.dart';
import 'package:peksoft_radio/features/library/data/library_repository_impl.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/domain/stream_variant_selector.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/profile/data/settings_repository_impl.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/domain/station_repository.dart';
import 'package:peksoft_radio/features/subscription/data/entitlement_repository_impl.dart';

import 'helpers/fake_audio_player_service.dart';
import 'helpers/fake_connectivity_service.dart';
import 'helpers/fake_report_queue_repository.dart';
import 'helpers/mock_repository_overrides.dart';

const Station _hqVariant = Station(
  id: 'st-hq',
  name: 'Jazz FM London',
  streamUrl: 'https://stream.example.com/jazz-320.aac',
  countryCode: 'GB',
  countryName: 'United Kingdom',
  codec: 'AAC',
  bitrateKbps: 320,
  isHttps: true,
  isWorking: true,
);

const Station _lqVariant = Station(
  id: 'st-lq',
  name: 'Jazz FM London',
  streamUrl: 'https://stream.example.com/jazz-64.aac',
  countryCode: 'GB',
  countryName: 'United Kingdom',
  codec: 'AAC',
  bitrateKbps: 64,
  isHttps: true,
  isWorking: true,
);

const Station _otherStation = Station(
  id: 'st-other',
  name: 'FIP Paris',
  streamUrl: 'https://stream.example.com/fip.mp3',
  countryCode: 'FR',
  countryName: 'France',
  codec: 'MP3',
  bitrateKbps: 128,
  isHttps: true,
  isWorking: true,
);

class _NoopStationRepo implements StationRepository {
  @override
  Future<Result<Station>> getStationById(String id) async =>
      const Success<Station>(_hqVariant);

  @override
  Future<Result<List<Station>>> getSimilarStations(
    Station station, {
    int limit = 10,
  }) async => const Success<List<Station>>(<Station>[_otherStation]);

  @override
  Future<Result<void>> reportClick(String stationId) async =>
      const Success<void>(null);
}

class _VariantCatalogRepo implements CatalogRepository {
  @override
  Future<Result<List<Country>>> getCountries({
    bool forceRefresh = false,
  }) async => const Success<List<Country>>(<Country>[]);

  @override
  Future<Result<List<Genre>>> getGenres({bool forceRefresh = false}) async =>
      const Success<List<Genre>>(<Genre>[]);

  @override
  Future<Result<List<Language>>> getLanguages({
    bool forceRefresh = false,
  }) async => const Success<List<Language>>(<Language>[]);

  @override
  Future<Result<List<Station>>> getTopStations({
    int limit = 100,
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    return const Success<List<Station>>(<Station>[
      _hqVariant,
      _lqVariant,
      _otherStation,
    ]);
  }

  @override
  Future<Result<List<Station>>> getStationsByCountry(
    String countryCode, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    return const Success<List<Station>>(<Station>[_hqVariant, _lqVariant]);
  }

  @override
  Future<Result<List<Station>>> getStationsByGenre(
    String genreId, {
    StationFilter filter = const StationFilter(),
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    return const Success<List<Station>>(<Station>[]);
  }

  @override
  Future<Result<List<Station>>> searchStations(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
    bool forceRefresh = false,
  }) async {
    return const Success<List<Station>>(<Station>[
      _hqVariant,
      _lqVariant,
      _otherStation,
    ]);
  }
}

void main() {
  group('Milestone 3.4 Listening Features', () {
    test('sleep timer countdown fades volume and pauses playback', () async {
      final AppDatabase db = AppDatabase.inMemory();
      addTearDown(db.close);
      final FakeAudioPlayerService audio = FakeAudioPlayerService();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(_VariantCatalogRepo()),
          libraryRepositoryProvider.overrideWithValue(
            LibraryRepositoryImpl(
              database: db,
              entitlementRepository: const EntitlementRepositoryImpl(),
            ),
          ),
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepositoryImpl(database: db),
          ),
          stationRepositoryProvider.overrideWithValue(_NoopStationRepo()),
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(),
          ),
          reportQueueRepositoryProvider.overrideWithValue(
            FakeReportQueueRepository(),
          ),
          audioPlayerServiceProvider.overrideWithValue(audio),
          sleepTimerTickProvider.overrideWithValue(
            const Duration(milliseconds: 30),
          ),
          sleepFadeDurationProvider.overrideWithValue(
            const Duration(milliseconds: 180),
          ),
        ],
      );
      addTearDown(container.dispose);

      final PlayerViewModel vm = container.read(
        playbackViewModelProvider.notifier,
      );
      await vm.playStation(_hqVariant);
      expect(audio.volume, 1.0);

      vm.setSleepTimer(const Duration(milliseconds: 210));
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(audio.volume, lessThan(1.0));

      await Future<void>.delayed(const Duration(milliseconds: 260));
      final PlayerState afterExpiry = container.read(playbackViewModelProvider);
      expect(afterExpiry.playback.status, PlaybackStatus.paused);
      expect(afterExpiry.playback.sleepTimerRemaining, isNull);
      expect(audio.pauseCalls, 1);
      expect(audio.volume, 1.0);
    });

    test(
      'data-saver mode prefers lower-bitrate variant when available',
      () async {
        expect(
          selectBitrateVariant(_hqVariant, const <Station>[
            _hqVariant,
            _lqVariant,
          ], dataSaver: false).id,
          'st-hq',
        );
        final Station picked = selectBitrateVariant(_hqVariant, const <Station>[
          _hqVariant,
          _lqVariant,
        ], dataSaver: true);
        expect(picked.id, 'st-lq');
        expect(picked.fallbackStreamUrl, _hqVariant.streamUrl);

        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);
        final SettingsRepositoryImpl settingsRepo = SettingsRepositoryImpl(
          database: db,
        );
        await settingsRepo.saveSettings(const UserSettings(dataSaver: true));

        final FakeAudioPlayerService audio = FakeAudioPlayerService();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(_VariantCatalogRepo()),
            libraryRepositoryProvider.overrideWithValue(
              LibraryRepositoryImpl(
                database: db,
                entitlementRepository: const EntitlementRepositoryImpl(),
              ),
            ),
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
            stationRepositoryProvider.overrideWithValue(_NoopStationRepo()),
            connectivityServiceProvider.overrideWithValue(
              FakeConnectivityService(),
            ),
            reportQueueRepositoryProvider.overrideWithValue(
              FakeReportQueueRepository(),
            ),
            audioPlayerServiceProvider.overrideWithValue(audio),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_hqVariant);

        expect(audio.lastPlayedStation?.id, 'st-lq');
        expect(audio.attemptedUrls.first, _lqVariant.streamUrl);
      },
    );

    test(
      'local library enforces free-tier limits from EntitlementRepository',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);
        final FakeAudioPlayerService audio = FakeAudioPlayerService();
        final ProviderContainer container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            catalogRepositoryProvider.overrideWithValue(_VariantCatalogRepo()),
            libraryRepositoryProvider.overrideWithValue(
              LibraryRepositoryImpl(
                database: db,
                entitlementRepository: const EntitlementRepositoryImpl(),
              ),
            ),
            settingsRepositoryProvider.overrideWithValue(
              SettingsRepositoryImpl(database: db),
            ),
            audioPlayerServiceProvider.overrideWithValue(audio),
          ],
        );
        addTearDown(container.dispose);

        final LibraryViewModel libVm = container.read(
          libraryViewModelProvider.notifier,
        );
        await container.read(libraryViewModelProvider.future);

        for (int i = 0; i < 30; i++) {
          await libVm.toggleFavourite(
            _hqVariant.copyWith(id: 'fav-$i', name: 'Station $i'),
          );
        }
        await libVm.toggleFavourite(
          _hqVariant.copyWith(id: 'fav-31', name: 'Station 31'),
        );

        final LibraryState afterFavLimit = container
            .read(libraryViewModelProvider)
            .requireValue;
        expect(afterFavLimit.favourites.length, 30);
        expect(
          afterFavLimit.limitReachedFailure,
          isA<EntitlementRequiredFailure>(),
        );

        await libVm.createCollection('Morning');
        await libVm.createCollection('Workout');
        await libVm.createCollection('Evening');
        final LibraryState afterColLimit = container
            .read(libraryViewModelProvider)
            .requireValue;
        expect(afterColLimit.collections.length, 2);
        expect(
          afterColLimit.limitReachedFailure,
          isA<EntitlementRequiredFailure>(),
        );

        final libraryRepo = container.read(libraryRepositoryProvider);
        for (int i = 0; i < 12; i++) {
          await libraryRepo.logSongHistory(
            SongHistoryEntry(
              id: 'song-$i',
              stationId: 'st-hq',
              stationName: 'Jazz FM London',
              trackTitle: 'Track $i',
              playedAt: DateTime(2026, 1, 1, 0, i),
            ),
          );
        }
        await libVm.refresh();
        expect(
          container
              .read(libraryViewModelProvider)
              .requireValue
              .songHistory
              .length,
          10,
        );
      },
    );

    test('Surprise me plays a working station from the catalog', () async {
      final AppDatabase db = AppDatabase.inMemory();
      addTearDown(db.close);
      final FakeAudioPlayerService audio = FakeAudioPlayerService();
      final ProviderContainer container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          catalogRepositoryProvider.overrideWithValue(_VariantCatalogRepo()),
          libraryRepositoryProvider.overrideWithValue(
            LibraryRepositoryImpl(
              database: db,
              entitlementRepository: const EntitlementRepositoryImpl(),
            ),
          ),
          settingsRepositoryProvider.overrideWithValue(
            SettingsRepositoryImpl(database: db),
          ),
          stationRepositoryProvider.overrideWithValue(_NoopStationRepo()),
          connectivityServiceProvider.overrideWithValue(
            FakeConnectivityService(),
          ),
          reportQueueRepositoryProvider.overrideWithValue(
            FakeReportQueueRepository(),
          ),
          audioPlayerServiceProvider.overrideWithValue(audio),
        ],
      );
      addTearDown(container.dispose);

      final Station? chosen = await container
          .read(playbackViewModelProvider.notifier)
          .playSurpriseMe(random: Random(0));

      expect(chosen, isNotNull);
      expect(
        container.read(playbackViewModelProvider).playback.status,
        PlaybackStatus.playing,
      );
    });

    testWidgets(
      'HomeScreen Surprise me button and NowPlayingScreen Share link work',
      (tester) async {
        final FakeAudioPlayerService audio = FakeAudioPlayerService();
        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(audioPlayerService: audio),
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const HomeScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Shuffle Stations'));
        await tester.pumpAndSettle();
        expect(
          container.read(playbackViewModelProvider).playback.currentStation,
          isNotNull,
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const NowPlayingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Share'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
