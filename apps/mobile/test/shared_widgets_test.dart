import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/dev_gallery/presentation/component_gallery_screen.dart';

void main() {
  testWidgets(
    'ComponentGalleryScreen renders all shared widgets at 1.3x scale',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const ComponentGalleryScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Component Gallery (Dev)'), findsOneWidget);
      expect(find.byType(StationLogo), findsWidgets);
      expect(find.byType(QualityBadge), findsWidgets);
      expect(find.byType(FilterChipBar), findsOneWidget);
      expect(find.byType(StationTile), findsWidgets);

      final verticalScrollable = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      await tester.scrollUntilVisible(
        find.byType(PrimaryButton),
        300,
        scrollable: verticalScrollable,
      );
      await tester.pump();
      expect(find.byType(PrimaryButton), findsWidgets);

      await tester.scrollUntilVisible(
        find.byType(AdSlotPlaceholder),
        300,
        scrollable: verticalScrollable,
      );
      await tester.pump();
      expect(find.byType(AdSlotPlaceholder), findsWidgets);

      await tester.scrollUntilVisible(
        find.byType(EmptyState),
        300,
        scrollable: verticalScrollable,
      );
      await tester.pump();
      expect(find.byType(EmptyState), findsWidgets);

      await tester.scrollUntilVisible(
        find.byType(ErrorState),
        300,
        scrollable: verticalScrollable,
      );
      await tester.pump();
      expect(find.byType(ErrorState), findsWidgets);

      await tester.scrollUntilVisible(
        find.byType(SkeletonList),
        300,
        scrollable: verticalScrollable,
      );
      await tester.pump();
      expect(find.byType(SkeletonList), findsWidgets);
    },
  );

  testWidgets('StationTile interactive buttons meet 48dp touch targets', (
    tester,
  ) async {
    var played = false;
    var favourited = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: StationTile(
            name: 'Wazobia FM: Lagos',
            countryLabel: 'Nigeria',
            genres: const ['Afrobeats', 'Talk'],
            onPlayTap: () => played = true,
            onFavouriteTap: () => favourited = true,
          ),
        ),
      ),
    );

    final favButton = find.byTooltip('Favourite');
    final playButton = find.byTooltip('Play');

    expect(
      tester.getSize(favButton).width,
      greaterThanOrEqualTo(AppSpacing.touchTarget),
    );
    expect(
      tester.getSize(favButton).height,
      greaterThanOrEqualTo(AppSpacing.touchTarget),
    );
    expect(
      tester.getSize(playButton).width,
      greaterThanOrEqualTo(AppSpacing.touchTarget),
    );
    expect(
      tester.getSize(playButton).height,
      greaterThanOrEqualTo(AppSpacing.touchTarget),
    );

    await tester.tap(favButton);
    await tester.tap(playButton);
    expect(favourited, isTrue);
    expect(played, isTrue);
  });
}
