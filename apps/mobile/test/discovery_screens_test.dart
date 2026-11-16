import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/explore/presentation/country_detail_screen.dart';
import 'package:peksoft_radio/features/explore/presentation/explore_screen.dart';
import 'package:peksoft_radio/features/explore/presentation/genre_detail_screen.dart';
import 'package:peksoft_radio/features/home/presentation/home_screen.dart';
import 'package:peksoft_radio/features/onboarding/presentation/splash_screen.dart';
import 'package:peksoft_radio/features/onboarding/presentation/welcome_screen.dart';
import 'package:peksoft_radio/features/search/presentation/filters_bottom_sheet.dart';
import 'package:peksoft_radio/features/search/presentation/search_screen.dart';
import 'package:peksoft_radio/features/station/presentation/station_detail_screen.dart';

import 'helpers/mock_repository_overrides.dart';

Widget _wrapAtScale13(Widget child) {
  return ProviderScope(
    overrides: mockRepositoryOverrides(),
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
  group('Milestone 1.3 Discovery Screens', () {
    testWidgets('Splash and Welcome screens render with Skip at 1.3x scale', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapAtScale13(const SplashScreen()));
      await tester.pumpAndSettle();
      expect(find.text('PekSoft Radio'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Skip to Home'), findsOneWidget);

      await tester.pumpWidget(_wrapAtScale13(const WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Tune into your world'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Start Listening'), 200);
      expect(find.text('Start Listening'), findsOneWidget);
    });

    testWidgets('Home screen renders curated collections and stations', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapAtScale13(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Curated collections'), findsOneWidget);
      expect(find.text('Live & working now'), findsOneWidget);
      expect(find.byType(AdSlotPlaceholder), findsOneWidget);
    });

    testWidgets('Explore screen switches across all 4 tabs', (tester) async {
      await tester.pumpWidget(_wrapAtScale13(const ExploreScreen()));
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

    testWidgets(
      'Search screen covers empty, results, no-results, and filters',
      (tester) async {
        await tester.pumpWidget(_wrapAtScale13(const SearchScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Try searching for'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Wazobia');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(find.text('Wazobia FM: Lagos'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'zzzz-no-match');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(find.text('No stations found'), findsOneWidget);

        await tester.tap(find.byTooltip('Filters'));
        await tester.pumpAndSettle();
        expect(find.text('Filters & Sort'), findsOneWidget);
        expect(find.text('Working now only'), findsOneWidget);
        final Switch switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isTrue);
      },
    );

    testWidgets('Country, Genre, and Station detail screens render cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapAtScale13(const CountryDetailScreen(countryCode: 'NG')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wazobia FM: Lagos'), findsOneWidget);

      await tester.pumpWidget(
        _wrapAtScale13(const GenreDetailScreen(genreName: 'Jazz')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jazz FM London'), findsOneWidget);

      await tester.pumpWidget(
        _wrapAtScale13(
          const StationDetailScreen(stationId: 'mock-ng-wazobia-lagos'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Play Station'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Similar stations'), 200);
      expect(find.text('Similar stations'), findsOneWidget);
    });

    test('StationFilterState defaults workingOnly to true', () {
      const StationFilterState defaults = StationFilterState();
      expect(defaults.workingOnly, isTrue);
      expect(defaults.activeFilterCount, 0);
    });
  });
}
