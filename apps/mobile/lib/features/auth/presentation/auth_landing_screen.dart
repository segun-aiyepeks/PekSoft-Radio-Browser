import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';

class AuthLandingScreen extends ConsumerWidget {
  const AuthLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final AuthState authState = ref.watch(authViewModelProvider);

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
            'Sign in to back up favourites, collections, and Plus status across devices.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              authState.error!.userMessage,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.s2xl),
          PrimaryButton(
            label: authState.isLoading
                ? 'Signing in...'
                : 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            onPressed: authState.isLoading
                ? null
                : () async {
                    final bool ok = await ref
                        .read(authViewModelProvider.notifier)
                        .signInWithGoogle();
                    if (!context.mounted) return;
                    final AuthState next = ref.read(authViewModelProvider);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signed in and library synced.'),
                        ),
                      );
                      context.pop();
                    } else if (next.pendingLinkEmail != null) {
                      context.push('/auth/sign-in');
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: OutlinedButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () => context.push('/auth/sign-in'),
              icon: const Icon(Icons.email_outlined),
              label: const Text('Sign in with Email'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: TextButton(
              onPressed: authState.isLoading
                  ? null
                  : () => context.push('/auth/sign-up'),
              child: const Text('Create an account'),
            ),
          ),
        ],
      ),
    );
  }
}
