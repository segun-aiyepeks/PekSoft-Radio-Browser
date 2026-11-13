import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/auth/presentation/auth_landing_screen.dart';
import 'package:peksoft_radio/features/auth/presentation/sign_in_screen.dart';
import 'package:peksoft_radio/features/auth/presentation/sign_up_screen.dart';
import 'package:peksoft_radio/features/library/presentation/library_screen.dart';
import 'package:peksoft_radio/features/profile/presentation/about_legal_screen.dart';
import 'package:peksoft_radio/features/profile/presentation/delete_account_screen.dart';
import 'package:peksoft_radio/features/profile/presentation/profile_screen.dart';
import 'package:peksoft_radio/features/profile/presentation/settings_screen.dart';
import 'package:peksoft_radio/features/subscription/presentation/paywall_screen.dart';
import 'package:peksoft_radio/features/subscription/presentation/subscription_management_screen.dart';
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
  group('Milestone 1.5 Account and Money Screens', () {
    setUp(() {
      mockSessionController.signOutMock();
      mockSessionController.setOfflineSimulated(false);
    });

    testWidgets('Library renders all 4 tabs and free-tier prompts', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapAtScale13(const LibraryScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Go Pro'), findsOneWidget);

      await tester.tap(find.text('Recents'));
      await tester.pumpAndSettle();
      expect(find.text('Wazobia FM: Lagos'), findsOneWidget);

      await tester.tap(find.text('Collections'));
      await tester.pumpAndSettle();
      expect(find.text('West Africa Pulse'), findsOneWidget);

      await tester.tap(find.text('Song History'));
      await tester.pumpAndSettle();
      expect(find.text('Burna Boy — City Boys'), findsOneWidget);
    });

    testWidgets('Auth landing, SignIn, and SignUp validate visually', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapAtScale13(const AuthLandingScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google (Mock)'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await tester.pumpWidget(_wrapAtScale13(const SignInScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );

      await tester.pumpWidget(_wrapAtScale13(const SignUpScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();
      expect(find.text('Enter your name'), findsOneWidget);
    });

    testWidgets('Paywall and Subscription management render at 1.3x scale', (
      tester,
    ) async {
      await tester.pumpWidget(_wrapAtScale13(const PaywallScreen()));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Annual'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Restore Purchases'), 200);
      expect(find.text('Restore Purchases'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Terms of Service'), 200);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);

      await tester.pumpWidget(
        _wrapAtScale13(const SubscriptionManagementScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Free Plan'), findsOneWidget);
    });

    testWidgets(
      'Profile, Settings, DeleteAccount, AboutLegal, and OfflineBanner render',
      (tester) async {
        await tester.pumpWidget(_wrapAtScale13(const ProfileScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Guest Listener'), findsOneWidget);

        await tester.pumpWidget(_wrapAtScale13(const SettingsScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Data Saver'), findsOneWidget);

        await tester.pumpWidget(_wrapAtScale13(const DeleteAccountScreen()));
        await tester.pumpAndSettle();
        expect(find.text('This action is permanent (Mock)'), findsOneWidget);

        await tester.pumpWidget(_wrapAtScale13(const AboutLegalScreen()));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Station data by Radio Browser'),
          findsOneWidget,
        );

        await tester.pumpWidget(
          _wrapAtScale13(const Scaffold(body: OfflineBanner())),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('You\'re offline · Cached library available'),
          findsOneWidget,
        );
      },
    );
  });
}
