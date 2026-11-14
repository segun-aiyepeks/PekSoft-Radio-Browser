import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/data/report_queue_repository_impl.dart';
import 'package:peksoft_radio/features/station/domain/report_queue_repository.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/domain/station_repository.dart';
import 'package:peksoft_radio/mock/mock.dart';

import 'helpers/fake_audio_player_service.dart';
import 'helpers/fake_connectivity_service.dart';
import 'helpers/fake_report_queue_repository.dart';
import 'helpers/mock_repository_overrides.dart';

class _CountingStationRepository implements StationRepository {
  int clickCount = 0;
  String? lastClickedId;

  @override
  Future<Result<Station>> getStationById(String id) async {
    return Success<Station>(_stationWithFallback);
  }

  @override
  Future<Result<List<Station>>> getSimilarStations(
    Station station, {
    int limit = 10,
  }) async {
    return const Success<List<Station>>(<Station>[
      Station(
        id: 'sim-1',
        name: 'Similar FM',
        streamUrl: 'https://stream.example.com/similar',
        countryCode: 'NG',
        countryName: 'Nigeria',
        isHttps: true,
        isWorking: true,
      ),
    ]);
  }

  @override
  Future<Result<void>> reportClick(String stationId) async {
    clickCount += 1;
    lastClickedId = stationId;
    return const Success<void>(null);
  }
}

final Station _stationWithFallback = Station(
  id: mockStations.first.id,
  name: 'Cool FM Lagos',
  streamUrl: 'https://resolved.example.com/cool.aac',
  fallbackStreamUrl: 'http://origin.example.com/cool.mp3',
  countryCode: 'NG',
  countryName: 'Nigeria',
  codec: 'AAC',
  bitrateKbps: 128,
  isHttps: true,
  isWorking: true,
  genres: const <Genre>[Genre(id: 'afrobeats', name: 'Afrobeats')],
);

void main() {
  group('Milestone 3.3 Resilience (UX Journey J4)', () {
    test(
      'fails over from resolved URL to original URL and reports click on play',
      () async {
        final FakeAudioPlayerService audio = FakeAudioPlayerService()
          ..failingUrls.add('https://resolved.example.com/cool.aac');
        final _CountingStationRepository stationRepo =
            _CountingStationRepository();

        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(
            audioPlayerService: audio,
            stationRepository: stationRepo,
          ),
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_stationWithFallback);

        expect(audio.attemptedUrls, <String>[
          'https://resolved.example.com/cool.aac',
          'http://origin.example.com/cool.mp3',
        ]);
        expect(
          container.read(playbackViewModelProvider).playback.status,
          PlaybackStatus.playing,
        );
        expect(stationRepo.clickCount, 1);
        expect(stationRepo.lastClickedId, _stationWithFallback.id);
      },
    );

    test(
      'retries 3 times with back-off, then surfaces friendly error + similar stations',
      () async {
        final FakeAudioPlayerService audio = FakeAudioPlayerService()
          ..failingUrls.addAll(<String>[
            'https://resolved.example.com/cool.aac',
            'http://origin.example.com/cool.mp3',
          ]);
        final _CountingStationRepository stationRepo =
            _CountingStationRepository();

        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(
            audioPlayerService: audio,
            stationRepository: stationRepo,
          ),
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_stationWithFallback);

        // 1 initial attempt (2 URLs) + 3 retries (2 URLs each) = 8 attempts total.
        expect(audio.attemptedUrls.length, 8);
        final PlayerState state = container.read(playbackViewModelProvider);
        expect(state.playback.status, PlaybackStatus.unavailable);
        expect(
          state.playback.error?.userMessage,
          contains('Could not connect'),
        );
        expect(state.similarStations.length, 1);
        expect(state.similarStations.first.name, 'Similar FM');
      },
    );

    test(
      'auto-reconnects when connectivity returns after being offline',
      () async {
        final FakeAudioPlayerService audio = FakeAudioPlayerService()
          ..failingUrls.addAll(<String>[
            'https://resolved.example.com/cool.aac',
            'http://origin.example.com/cool.mp3',
          ]);
        final FakeConnectivityService connectivity = FakeConnectivityService(
          initialOnline: false,
        );
        final _CountingStationRepository stationRepo =
            _CountingStationRepository();

        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(
            audioPlayerService: audio,
            connectivityService: connectivity,
            stationRepository: stationRepo,
          ),
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_stationWithFallback);
        expect(
          container.read(playbackViewModelProvider).playback.status,
          PlaybackStatus.unavailable,
        );

        // Network returns and stream succeeds.
        audio.failingUrls.clear();
        connectivity.emitOnline(false);
        connectivity.emitOnline(true);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          container.read(playbackViewModelProvider).playback.status,
          PlaybackStatus.playing,
        );
        // Reported a click on both initial play and auto-reconnect play.
        expect(stationRepo.clickCount, 2);
      },
    );

    test(
      'queues Report broken locally in Drift without calling Radio Browser',
      () async {
        final AppDatabase db = AppDatabase.inMemory();
        addTearDown(db.close);
        final DriftReportQueueRepository repo = DriftReportQueueRepository(
          database: db,
        );

        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(reportQueueRepository: repo),
        );
        addTearDown(container.dispose);

        final PlayerViewModel vm = container.read(
          playbackViewModelProvider.notifier,
        );
        await vm.playStation(_stationWithFallback);
        vm.reportCurrentStation('Stream silent');
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          container.read(playbackViewModelProvider).reportSubmitted,
          isTrue,
        );
        final Result<List<PendingStationReport>> pending = await repo
            .getPendingReports();
        final List<PendingStationReport> items = switch (pending) {
          Success<List<PendingStationReport>>(:final data) => data,
          Failure<List<PendingStationReport>>() =>
            const <PendingStationReport>[],
        };
        expect(items.length, 1);
        expect(items.first.stationId, _stationWithFallback.id);
        expect(items.first.reason, 'Stream silent');
        expect(items.first.synced, isFalse);
      },
    );

    testWidgets(
      'NowPlayingScreen displays friendly unavailable error and similar stations',
      (tester) async {
        final FakeAudioPlayerService audio = FakeAudioPlayerService()
          ..failingUrls.addAll(<String>[
            'https://resolved.example.com/cool.aac',
            'http://origin.example.com/cool.mp3',
          ]);
        final FakeReportQueueRepository reportRepo =
            FakeReportQueueRepository();
        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(
            audioPlayerService: audio,
            reportQueueRepository: reportRepo,
          ),
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_stationWithFallback);

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

        expect(find.text('Station unavailable'), findsOneWidget);
        expect(
          find.textContaining('Could not connect to Cool FM Lagos'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Report broken'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('Similar stations'), 200);
        expect(find.text('Similar stations'), findsOneWidget);
      },
    );
  });
}
