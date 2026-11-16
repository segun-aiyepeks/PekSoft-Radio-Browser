import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/explore/presentation/explore_screen.dart';
import 'package:peksoft_radio/features/home/presentation/home_screen.dart';
import 'package:peksoft_radio/features/player/presentation/now_playing_screen.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/search/presentation/search_screen.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/subscription/presentation/paywall_screen.dart';
import 'package:peksoft_radio/mock/mock.dart';

import 'helpers/mock_repository_overrides.dart';

/// Allows minor cross-OS (Windows vs Linux) Skia/font anti-aliasing differences
/// while still catching real layout, colour, or component regressions.
class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(super.testFile, {required this.tolerance});

  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final ComparisonResult result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (!result.passed && result.diffPercent <= tolerance) {
      return true;
    }
    if (!result.passed) {
      final String error = await generateFailureOutput(result, golden, basedir);
      throw FlutterError(error);
    }
    return result.passed;
  }
}

Widget _goldenFrame({
  required Widget child,
  ThemeMode themeMode = ThemeMode.dark,
}) {
  return ProviderScope(
    overrides: mockRepositoryOverrides(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: child,
    ),
  );
}

void main() {
  goldenFileComparator = _TolerantGoldenFileComparator(
    Uri.file('test/golden_screens_test.dart'),
    tolerance: 0.03,
  );

  group('Milestone 1.6 Golden Tests (5 Key Screens)', () {
    setUp(() {
      mockSessionController.playStation(mockStations.first);
      mockSessionController.setSleepTimer(null);
      mockSessionController.setProMock(false);
    });

    testWidgets('HomeScreen golden (dark)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_goldenFrame(child: const HomeScreen()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_screen.png'),
      );
    });

    testWidgets('ExploreScreen golden (dark)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_goldenFrame(child: const ExploreScreen()));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ExploreScreen),
        matchesGoldenFile('goldens/explore_screen.png'),
      );
    });

    testWidgets('SearchScreen golden (dark)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _goldenFrame(child: const SearchScreen(initialQuery: 'FM')),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(SearchScreen),
        matchesGoldenFile('goldens/search_screen.png'),
      );
    });

    testWidgets('NowPlayingScreen golden (dark)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final ProviderContainer container = ProviderContainer(
        overrides: mockRepositoryOverrides(),
      );
      addTearDown(container.dispose);

      final MockStation first = mockStations.first;
      await container
          .read(playbackViewModelProvider.notifier)
          .playStation(
            Station(
              id: first.id,
              name: first.name,
              streamUrl: 'https://stream.example.com/${first.id}',
              homepage: first.homepage,
              faviconUrl: first.faviconUrl,
              usesFallbackLogo:
                  first.faviconUrl == null || first.faviconUrl!.isEmpty,
              isHttps: first.isHttps,
              isHls: first.isHls,
              isWorking: first.isWorking,
              countryCode: first.countryCode,
              countryName: first.country,
              genres: first.genres
                  .map((String g) => Genre(id: g.toLowerCase(), name: g))
                  .toList(growable: false),
              language: first.language,
              codec: first.codec,
              bitrateKbps: first.bitrateKbps,
              votes: first.votes,
              clickCount: first.clickCount,
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            home: const NowPlayingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(NowPlayingScreen),
        matchesGoldenFile('goldens/now_playing_screen.png'),
      );
    });

    testWidgets('PaywallScreen golden (light)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _goldenFrame(child: const PaywallScreen(), themeMode: ThemeMode.light),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(PaywallScreen),
        matchesGoldenFile('goldens/paywall_screen_light.png'),
      );
    });
  });
}
