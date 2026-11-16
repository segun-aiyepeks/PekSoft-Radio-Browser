import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';

class VerifyEmailScreen extends ConsumerWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final AuthState authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Icon(
            Icons.mark_email_read_outlined,
            size: AppSpacing.s3xl,
            color: colors.accent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Check your inbox',
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            authState.userEmail != null
                ? 'We sent a verification link to ${authState.userEmail}.'
                : 'We sent a verification link to your email address.',
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
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: authState.isLoading ? 'Checking...' : "I've Verified",
            onPressed: authState.isLoading
                ? null
                : () async {
                    final bool verified = await ref
                        .read(authViewModelProvider.notifier)
                        .reloadVerificationStatus();
                    if (!context.mounted) return;
                    if (verified) {
                      context.go('/profile');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Email is not verified yet. Check your inbox or resend.',
                          ),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: TextButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final bool ok = await ref
                          .read(authViewModelProvider.notifier)
                          .resendVerificationEmail();
                      if (!context.mounted) return;
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email resent.'),
                          ),
                        );
                      }
                    },
              child: const Text('Resend Email'),
            ),
          ),
        ],
      ),
    );
  }
}
