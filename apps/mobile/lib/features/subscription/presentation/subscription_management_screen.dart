import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

class SubscriptionManagementScreen extends StatelessWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListenableBuilder(
        listenable: mockSessionController,
        builder: (context, _) {
          final bool isPro = mockSessionController.isPro;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(
                    color: isPro ? colors.accent : colors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? 'PekSoft Pro (Mock)' : 'Free Plan',
                      style: AppTypography.h2.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isPro
                          ? 'Active · Renews automatically on Google Play / Paystack (Mock)'
                          : 'Up to 10 favourites, 2 custom collections, ad-supported.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!isPro)
                PrimaryButton(
                  label: 'Upgrade to Pro',
                  icon: Icons.workspace_premium_rounded,
                  onPressed: () => context.push('/paywall'),
                )
              else ...[
                PrimaryButton(
                  label: 'Change Plan',
                  icon: Icons.swap_horiz_rounded,
                  onPressed: () => context.push('/paywall'),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: AppSpacing.touchTarget,
                  child: OutlinedButton(
                    onPressed: () {
                      mockSessionController.setProMock(false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Subscription cancelled (mock).'),
                        ),
                      );
                    },
                    child: const Text('Cancel Subscription (Mock)'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
