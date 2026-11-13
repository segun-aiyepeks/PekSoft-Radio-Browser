import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

class AuthLandingScreen extends StatelessWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        actions: [
          Semantics(
            button: true,
            label: 'Continue as guest',
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: TextButton(
                onPressed: () => context.pop(),
                child: const Text('Skip'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Icon(
            Icons.radio_rounded,
            size: AppSpacing.s3xl,
            color: colors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Sync your radio library',
            textAlign: TextAlign.center,
            style: AppTypography.h1.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign in to back up favourites, collections, and Pro status across devices (mock UI).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s2xl),
          PrimaryButton(
            label: 'Continue with Google (Mock)',
            icon: Icons.g_mobiledata_rounded,
            onPressed: () {
              mockSessionController.signInMock(
                email: 'listener@peksoft.radio',
                displayName: 'Google Listener',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed in with Google (mock).')),
              );
              context.pop();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/auth/sign-in'),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Sign in with Email'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: TextButton(
              onPressed: () => context.push('/auth/sign-up'),
              child: const Text('Create an account'),
            ),
          ),
        ],
      ),
    );
  }
}
