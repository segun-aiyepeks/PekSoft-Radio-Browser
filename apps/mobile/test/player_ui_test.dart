import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/player/presentation/mini_player_slot.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/mock/mock.dart';

Widget _wrapAtScale13(Widget child) {
  return MaterialApp(
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
  );
}

void main() {
  group('Milestone 1.4 Player UI', () {
    setUp(() {
      mockSessionController.playStation(mockStations.first);
      mockSessionController.setSleepTimer(null);
    });

    testWidgets(
      'NowPlayingScreen renders artwork, quality badge, dev switcher, and all playback states at 1.3x scale',
      (tester) async {
        await tester.pumpWidget(_wrapAtScale13(const NowPlayingScreen()));
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

    testWidgets('Sleep timer and Report sheets open and apply mock state', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapAtScale13(const NowPlayingScreen()));
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
      expect(find.textContaining('Report recorded (mock):'), findsOneWidget);
    });

    testWidgets(
      'MiniPlayerSlot displays buffering, reconnecting, and unavailable states',
      (tester) async {
        await tester.pumpWidget(
          _wrapAtScale13(const Scaffold(body: MiniPlayerSlot())),
        );
        await tester.pumpAndSettle();
        expect(find.text('Playing · Nigeria'), findsOneWidget);

        mockSessionController.setPlaybackStatus(MockPlaybackStatus.buffering);
        await tester.pump();
        expect(find.text('Buffering stream...'), findsOneWidget);

        mockSessionController.setPlaybackStatus(
          MockPlaybackStatus.reconnecting,
        );
        await tester.pump();
        expect(find.text('Reconnecting...'), findsOneWidget);

        mockSessionController.setPlaybackStatus(MockPlaybackStatus.unavailable);
        await tester.pump();
        expect(find.text('Station unavailable'), findsOneWidget);
      },
    );
  });
}
