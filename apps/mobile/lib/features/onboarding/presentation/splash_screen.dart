import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

/// Phase 1 Splash screen previewable via `/splash`.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'PekSoft Radio Browser logo',
                  child: Container(
                    width: AppSpacing.s3xl + AppSpacing.xl,
                    height: AppSpacing.s3xl + AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(color: colors.accent),
                    ),
                    child: Icon(
                      Icons.radio_rounded,
                      size: AppSpacing.s3xl,
                      color: colors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'PekSoft Radio',
                  style: AppTypography.display.copyWith(
                    color: colors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Live radio from every corner of the world',
                  style: AppTypography.body.copyWith(
                    color: colors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s2xl),
                PrimaryButton(
                  label: 'Get Started',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => context.go('/welcome'),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: AppSpacing.touchTarget,
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Skip to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
