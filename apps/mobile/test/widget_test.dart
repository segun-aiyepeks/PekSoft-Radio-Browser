import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/main.dart';

void main() {
  testWidgets('Shell renders 4 tabs and persistent mini-player slot', (
    tester,
  ) async {
    await tester.pumpWidget(const PekSoftRadioApp());
    await tester.pumpAndSettle();

    final navBar = find.byType(NavigationBar);
    expect(
      find.descendant(of: navBar, matching: find.text('Home')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Explore')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Library')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: navBar, matching: find.text('Profile')),
      findsOneWidget,
    );
    expect(find.text('Wazobia FM: Lagos'), findsWidgets);

    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Explore')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Countries'), findsOneWidget);
    expect(find.text('Wazobia FM: Lagos'), findsWidgets);

    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Library')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Favourites'), findsOneWidget);

    await tester.tap(
      find.descendant(of: navBar, matching: find.text('Profile')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Dark-first theme uses design tokens', (tester) async {
    await tester.pumpWidget(const PekSoftRadioApp());
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, isNull);
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(
      materialApp.darkTheme?.scaffoldBackgroundColor,
      AppDarkColors.background,
    );
    expect(
      materialApp.theme?.scaffoldBackgroundColor,
      AppLightColors.background,
    );
  });
}
