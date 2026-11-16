import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/player/presentation/mini_player_slot.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/main.dart';

import 'fake_audio_player_service.dart';
import 'mock_repository_overrides.dart';

/// Shared end-to-end play flow test body usable from both `integration_test/`
/// (on-device/emulator) and `test/` (headless VM widget runner).
Future<void> runPlayFlowIntegrationTest(WidgetTester tester) async {
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final FakeAudioPlayerService fakeAudio = FakeAudioPlayerService();

  await tester.pumpWidget(
    PekSoftRadioApp(
      overrides: mockRepositoryOverrides(audioPlayerService: fakeAudio),
    ),
  );
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();

  // Dismiss Welcome if this is a fresh onboarding state.
  final Finder skipButton = find.text('Skip');
  if (skipButton.evaluate().isNotEmpty) {
    await tester.tap(skipButton);
    await tester.pumpAndSettle();
  }

  expect(find.text('Live & working now'), findsOneWidget);

  // Scroll the lazy SliverList into view if the header occupies the 800x600 viewport.
  if (find.byType(StationTile).evaluate().isEmpty) {
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  // Start playback from the first station tile's play button.
  final Finder firstPlayButton = find
      .descendant(
        of: find.byType(StationTile).first,
        matching: find.byIcon(Icons.play_arrow_rounded),
      )
      .first;
  await tester.tap(firstPlayButton);
  await tester.pumpAndSettle();

  expect(fakeAudio.attemptedUrls, isNotEmpty);

  // Open Now Playing from the persistent mini-player.
  final Finder miniPlayer = find.byType(MiniPlayerSlot);
  expect(miniPlayer, findsOneWidget);
  await tester.tap(miniPlayer);
  await tester.pumpAndSettle();

  expect(find.byType(NowPlayingScreen), findsOneWidget);

  // Emit an ICY track update and verify it renders + records song history.
  fakeAudio.emitIcyTitle('Miles Davis - So What');
  await tester.pumpAndSettle();
  expect(find.text('Miles Davis - So What'), findsOneWidget);

  // Favourite the current station from Now Playing.
  final Finder favButton = find
      .descendant(
        of: find.byType(NowPlayingScreen),
        matching: find.byIcon(Icons.favorite_border_rounded),
      )
      .first;
  await tester.tap(favButton);
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: find.byType(NowPlayingScreen),
      matching: find.byIcon(Icons.favorite_rounded),
    ),
    findsOneWidget,
  );

  // Close Now Playing and verify Library reflects favourite + song history.
  final Finder collapseButton = find
      .descendant(
        of: find.byType(NowPlayingScreen),
        matching: find.byIcon(Icons.keyboard_arrow_down_rounded),
      )
      .first;
  await tester.tap(collapseButton);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Library'));
  await tester.pumpAndSettle();
  expect(find.byType(StationTile), findsWidgets);

  await tester.ensureVisible(find.text('Song History'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Song History'));
  await tester.pumpAndSettle();
  expect(
    find.descendant(
      of: find.byType(TabBarView),
      matching: find.text('Miles Davis - So What'),
    ),
    findsOneWidget,
  );
}
