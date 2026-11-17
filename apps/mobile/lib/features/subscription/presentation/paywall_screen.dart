import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/subscription/domain/billing_service.dart';
import 'package:peksoft_radio/features/subscription/presentation/view_models/subscription_view_model.dart';

/// Paywall screen wired to Google Play Billing local-currency prices,
/// purchase flow, success state, restore purchases, and optional 24h rewarded ad.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static const List<({IconData icon, String title, String subtitle})>
  _benefits = <({IconData icon, String title, String subtitle})>[
    (
      icon: Icons.block_rounded,
      title: 'Zero Banner or Audio Ads',
      subtitle: 'Uninterrupted listening across every station.',
    ),
    (
      icon: Icons.favorite_rounded,
      title: 'Unlimited Favourites & Collections',
      subtitle: 'Save and organize as many stations as you want.',
    ),
    (
      icon: Icons.history_rounded,
      title: 'Full Song History & 200 Recents',
      subtitle: 'Never lose track of a song you heard on air.',
    ),
    (
      icon: Icons.tune_rounded,
      title: 'Custom Sleep Timer & Advanced Filters',
      subtitle: 'Fade-out sleep timer, bitrate/codec filters, and EQ.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final AsyncValue<SubscriptionState> subAsync = ref.watch(
      subscriptionViewModelProvider,
    );
    final SubscriptionState subState =
        subAsync.asData?.value ?? const SubscriptionState();
    final SubscriptionViewModel vm = ref.read(
      subscriptionViewModelProvider.notifier,
    );

    final StoreProduct? monthlyProduct = subState.productFor(
      BillingPeriod.monthly,
    );
    final StoreProduct? annualProduct = subState.productFor(
      BillingPeriod.annual,
    );
    final String monthlyPrice = monthlyProduct != null
        ? '${monthlyProduct.price} / mo'
        : '\$2.99 / mo';
    final String annualPrice = annualProduct != null
        ? '${annualProduct.price} / yr'
        : '\$23.99 / yr';
    final bool isAnnual = subState.billingPeriod == BillingPeriod.annual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PekSoft Plus'),
        automaticallyImplyLeading: false,
        actions: [
          Semantics(
            button: true,
            label: 'Close paywall',
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  vm.clearPurchaseSuccess();
                  if (context.canPop()) {
                    context.pop();
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: subState.purchaseSuccess
          ? _PurchaseSuccessView(
              onContinue: () {
                vm.clearPurchaseSuccess();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Upgrade your radio experience',
                  style: AppTypography.h1.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Auto-renews via Google Play. Cancel anytime in Play Store.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (subState.purchasePending) ...[
                  const SizedBox(height: AppSpacing.md),
                  _StatusBanner(
                    icon: Icons.hourglass_top_rounded,
                    color: colors.accent,
                    message:
                        'Purchase pending — Plus unlocks as soon as Google Play confirms.',
                  ),
                ],
                if (subState.error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _StatusBanner(
                    icon: Icons.error_outline_rounded,
                    color: colors.error,
                    message: subState.error!.userMessage,
                  ),
                ],
                if (subState.statusMessage != null &&
                    !subState.purchasePending) ...[
                  const SizedBox(height: AppSpacing.md),
                  _StatusBanner(
                    icon: Icons.info_outline_rounded,
                    color: colors.accent,
                    message: subState.statusMessage!,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _PlanCard(
                        title: 'Monthly',
                        price: monthlyPrice,
                        badge: null,
                        selected: !isAnnual,
                        onTap: () =>
                            vm.selectBillingPeriod(BillingPeriod.monthly),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _PlanCard(
                        title: 'Annual',
                        price: annualPrice,
                        badge: 'Save 33%',
                        selected: isAnnual,
                        onTap: () =>
                            vm.selectBillingPeriod(BillingPeriod.annual),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                for (final item in _benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: colors.accent),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTypography.title.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                              Text(
                                item.subtitle,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: isAnnual
                      ? 'Continue with Annual ($annualPrice)'
                      : 'Continue with Monthly ($monthlyPrice)',
                  icon: Icons.workspace_premium_rounded,
                  isLoading: subState.isProcessing,
                  onPressed: subState.isProcessing ? null : vm.startPurchase,
                ),
                if (!subState.featureGate.isPaidPlus) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: AppSpacing.touchTarget,
                    child: OutlinedButton.icon(
                      onPressed: subState.isProcessing
                          ? null
                          : vm.watchRewardedAdForPlusPass,
                      icon: const Icon(Icons.play_circle_outline_rounded),
                      label: const Text('Watch an ad: 24 hours of Plus'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: SizedBox(
                    height: AppSpacing.touchTarget,
                    child: TextButton(
                      onPressed: subState.isProcessing
                          ? null
                          : vm.restorePurchases,
                      child: const Text('Restore Purchases'),
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.md,
                  children: [
                    SizedBox(
                      height: AppSpacing.touchTarget,
                      child: TextButton(
                        onPressed: () => context.push('/about'),
                        child: const Text('Terms of Service'),
                      ),
                    ),
                    SizedBox(
                      height: AppSpacing.touchTarget,
                      child: TextButton(
                        onPressed: () => context.push('/about'),
                        child: const Text('Privacy Policy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PurchaseSuccessView extends StatelessWidget {
  const _PurchaseSuccessView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 64, color: colors.accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              'PekSoft Plus Active',
              style: AppTypography.h1.copyWith(color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All ads are removed and unlimited favourites, collections, and song history are unlocked.',
              style: AppTypography.body.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'Start Listening',
              icon: Icons.radio_rounded,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title plan, $price${badge != null ? ', $badge' : ''}',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchTarget,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: selected ? colors.accent : colors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                    child: Text(
                      badge!,
                      style: AppTypography.caption.copyWith(
                        color: colors.onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  price,
                  style: AppTypography.body.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
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
