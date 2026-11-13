import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
            'We sent a verification link to your email address (mock UI).',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          PrimaryButton(
            label: 'I\'ve Verified (Mock)',
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verification email resent (mock).'),
                  ),
                );
              },
              child: const Text('Resend Email'),
            ),
          ),
        ],
      ),
    );
  }
}
