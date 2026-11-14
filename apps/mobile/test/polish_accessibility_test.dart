import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/features/explore/presentation/explore_screen.dart';
import 'package:peksoft_radio/features/home/presentation/home_screen.dart';
import 'package:peksoft_radio/features/library/presentation/library_screen.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/features/profile/presentation/profile_screen.dart';
import 'package:peksoft_radio/features/profile/presentation/settings_screen.dart';
import 'package:peksoft_radio/features/search/presentation/search_screen.dart';
import 'package:peksoft_radio/features/subscription/presentation/paywall_screen.dart';

import 'helpers/mock_repository_overrides.dart';

Widget _wrapViewport({
  required Widget child,
  required Size size,
  ThemeMode themeMode = ThemeMode.dark,
}) {
  return ProviderScope(
    overrides: mockRepositoryOverrides(),
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: const TextScaler.linear(1.3),
      ),
      child: MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );
}

void main() {
  group('Milestone 1.6 Accessibility, Landscape, and Tablet Polish', () {
    final List<({String name, Widget Function() builder})> screens =
        <({String name, Widget Function() builder})>[
          (name: 'HomeScreen', builder: () => const HomeScreen()),
          (name: 'ExploreScreen', builder: () => const ExploreScreen()),
          (
            name: 'SearchScreen',
            builder: () => const SearchScreen(initialQuery: 'FM'),
          ),
          (name: 'NowPlayingScreen', builder: () => const NowPlayingScreen()),
          (name: 'LibraryScreen', builder: () => const LibraryScreen()),
          (name: 'PaywallScreen', builder: () => const PaywallScreen()),
          (name: 'ProfileScreen', builder: () => const ProfileScreen()),
          (name: 'SettingsScreen', builder: () => const SettingsScreen()),
        ];

    testWidgets('Key screens pass accessibility guidelines in dark & light', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      try {
        for (final entry in screens) {
          for (final ThemeMode mode in <ThemeMode>[
            ThemeMode.dark,
            ThemeMode.light,
          ]) {
            await tester.pumpWidget(
              _wrapViewport(
                child: entry.builder(),
                size: const Size(390, 844),
                themeMode: mode,
              ),
            );
            await tester.pumpAndSettle();

            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
          }
        }
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Key screens render without overflow in landscape & tablet', (
      tester,
    ) async {
      const List<Size> viewports = <Size>[
        Size(844, 390), // Phone landscape
        Size(1024, 768), // Tablet
      ];

      for (final Size viewport in viewports) {
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        for (final entry in screens) {
          await tester.pumpWidget(
            _wrapViewport(child: entry.builder(), size: viewport),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.name} $viewport',
          );
        }
      }
    });
  });
}
