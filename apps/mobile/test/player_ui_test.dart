import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/mini_player_slot.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/mock/mock.dart';

import 'helpers/mock_repository_overrides.dart';

final Station _testStation = Station(
  id: mockStations.first.id,
  name: 'Wazobia FM: Lagos',
  streamUrl: 'https://stream.example.com/wazobia',
  countryCode: 'NG',
  countryName: 'Nigeria',
  language: 'Pidgin',
  codec: 'AAC',
  bitrateKbps: 128,
  isHttps: true,
  isWorking: true,
  genres: const <Genre>[Genre(id: 'afrobeats', name: 'Afrobeats')],
);

Widget _wrapAtScale13(Widget child, {required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      builder: (context, inner) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.3)),
        child: inner!,
      ),
      home: child,
    ),
  );
}

void main() {
  group('Player UI (wired to PlaybackViewModel)', () {
    testWidgets(
      'NowPlayingScreen renders artwork, quality badge, dev switcher, and all playback states at 1.3x scale',
      (tester) async {
        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_testStation);

        await tester.pumpWidget(
          _wrapAtScale13(const NowPlayingScreen(), container: container),
        );
        await tester.pumpAndSettle();

        expect(find.text('NOW PLAYING'), findsOneWidget);
        expect(find.text('Wazobia FM: Lagos'), findsOneWidget);
        expect(find.byType(QualityBadge), findsWidgets);
        expect(
          find.text('Dev State Switcher (Preview Playback States)'),
          findsOneWidget,
        );
        expect(find.text('LIVE · Streaming'), findsOneWidget);

        await tester.tap(find.text('buffering'));
        await tester.pump();
        expect(find.text('Buffering stream...'), findsOneWidget);

        await tester.tap(find.text('reconnecting'));
        await tester.pump();
        expect(find.text('Reconnecting...'), findsOneWidget);

        await tester.tap(find.text('unavailable'));
        await tester.pump();
        expect(find.text('Station unavailable'), findsOneWidget);
        expect(find.text('Report broken'), findsOneWidget);

        await tester.scrollUntilVisible(find.text('Similar stations'), 200);
        expect(find.text('Similar stations'), findsOneWidget);
      },
    );

    testWidgets('Sleep timer and Report sheets open and apply state', (
      tester,
    ) async {
      final ProviderContainer container = ProviderContainer(
        overrides: mockRepositoryOverrides(),
      );
      addTearDown(container.dispose);

      await container
          .read(playbackViewModelProvider.notifier)
          .playStation(_testStation);

      await tester.pumpWidget(
        _wrapAtScale13(const NowPlayingScreen(), container: container),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.byTooltip('Sleep Timer'), 200);
      await tester.ensureVisible(find.byTooltip('Sleep Timer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sleep Timer'));
      await tester.pumpAndSettle();
      expect(find.text('Sleep Timer'), findsOneWidget);
      await tester.tap(find.text('30 minutes'));
      await tester.pumpAndSettle();
      expect(find.text('Sleep: 30m'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Report'), 200);
      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      expect(find.text('Submit Report'), findsOneWidget);
      await tester.tap(find.text('Submit Report'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Report recorded:'), findsOneWidget);
    });

    testWidgets(
      'MiniPlayerSlot displays buffering, reconnecting, and unavailable states',
      (tester) async {
        final ProviderContainer container = ProviderContainer(
          overrides: mockRepositoryOverrides(),
        );
        addTearDown(container.dispose);

        await container
            .read(playbackViewModelProvider.notifier)
            .playStation(_testStation);

        await tester.pumpWidget(
          _wrapAtScale13(
            const Scaffold(body: MiniPlayerSlot()),
            container: container,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Playing · Nigeria'), findsOneWidget);

        final PlayerViewModel notifier = container.read(
          playbackViewModelProvider.notifier,
        );
        notifier.setPlaybackStatus(PlaybackStatus.buffering);
        await tester.pump();
        expect(find.text('Buffering stream...'), findsOneWidget);

        notifier.setPlaybackStatus(PlaybackStatus.reconnecting);
        await tester.pump();
        expect(find.text('Reconnecting...'), findsOneWidget);

        notifier.setPlaybackStatus(PlaybackStatus.unavailable);
        await tester.pump();
        expect(find.text('Station unavailable'), findsOneWidget);
      },
    );
  });
}
