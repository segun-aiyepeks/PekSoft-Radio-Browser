import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/mini_player_slot.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

import 'helpers/fake_audio_player_service.dart';
import 'helpers/mock_repository_overrides.dart';

const Station _hlsStation = Station(
  id: 'st-hls-1',
  name: 'BBC World Service',
  streamUrl: 'https://stream.example.com/bbc.m3u8',
  countryCode: 'GB',
  countryName: 'United Kingdom',
  language: 'English',
  codec: 'AAC',
  bitrateKbps: 128,
  isHttps: true,
  isHls: true,
  isWorking: true,
  genres: <Genre>[Genre(id: 'news', name: 'News')],
);

void main() {
  group('Milestone 3.2 Audio Engine & PlaybackViewModel', () {
    test(
      'PlaybackViewModel delegates play, pause, resume, stop, and ICY metadata',
      () async {
        final FakeAudioPlayerService fakeAudio = FakeAudioPlayerService();
        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(audioPlayerService: fakeAudio),
        );
        addTearDown(container.dispose);

        final PlayerViewModel vm = container.read(
          playbackViewModelProvider.notifier,
        );
        await vm.playStation(_hlsStation);

        expect(fakeAudio.lastPlayedStation, _hlsStation);
        expect(
          container.read(playbackViewModelProvider).playback.status,
          PlaybackStatus.playing,
        );

        vm.togglePlayPause();
        expect(fakeAudio.pauseCalls, 1);
        expect(
          container.read(playbackViewModelProvider).playback.status,
          PlaybackStatus.paused,
        );

        vm.togglePlayPause();
        expect(fakeAudio.resumeCalls, 1);
        expect(
          container.read(playbackViewModelProvider).playback.status,
          PlaybackStatus.playing,
        );

        fakeAudio.emitIcyTitle('Burna Boy - City Boys');
        await Future<void>.delayed(Duration.zero);
        expect(
          container.read(playbackViewModelProvider).playback.icyTitle,
          'Burna Boy - City Boys',
        );
        final Result<List<SongHistoryEntry>> historyRes = await container
            .read(libraryRepositoryProvider)
            .getSongHistory();
        final List<SongHistoryEntry> history = switch (historyRes) {
          Success<List<SongHistoryEntry>>(:final data) => data,
          Failure<List<SongHistoryEntry>>() => const <SongHistoryEntry>[],
        };
        expect(history.first.trackTitle, 'Burna Boy - City Boys');

        vm.stop();
        expect(fakeAudio.stopCalls, 1);
        expect(
          container.read(playbackViewModelProvider).playback.currentStation,
          isNull,
        );
      },
    );

    testWidgets(
      'MiniPlayerSlot and NowPlayingScreen react to ICY track metadata and play/pause',
      (tester) async {
        final FakeAudioPlayerService fakeAudio = FakeAudioPlayerService();
        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(audioPlayerService: fakeAudio),
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_hlsStation);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.dark(),
              home: const Scaffold(
                body: Column(
                  children: [
                    Expanded(child: NowPlayingScreen()),
                    MiniPlayerSlot(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        fakeAudio.emitIcyTitle('Newsday Live');
        await tester.pumpAndSettle();

        expect(find.text('Newsday Live'), findsNWidgets(2));
      },
    );
  });
}
