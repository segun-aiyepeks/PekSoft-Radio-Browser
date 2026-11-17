import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';
import 'package:peksoft_radio/features/subscription/presentation/view_models/subscription_view_model.dart';

/// Subscription lifecycle management screen: active Plus status, billing-problem
/// grace banner, graceful downgrade notice on expiry, Google Play manage-subscription
/// deep link, and restore purchases.
class SubscriptionManagementScreen extends ConsumerWidget {
  const SubscriptionManagementScreen({
    super.key,
    this.onOpenManageSubscription,
  });

  final Future<void> Function(Uri uri)? onOpenManageSubscription;

  static const MethodChannel _platformChannel = MethodChannel(
    'com.peksoft.radio/links',
  );

  Future<void> _launchManageSubscription(BuildContext context, Uri uri) async {
    if (onOpenManageSubscription != null) {
      await onOpenManageSubscription!(uri);
      return;
    }
    try {
      await _platformChannel.invokeMethod<void>('openUrl', <String, String>{
        'url': uri.toString(),
      });
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manage subscription in Google Play: $uri')),
        );
      }
    }
  }

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
    final Entitlement entitlement = subState.entitlement;
    final FeatureGate gate = subState.featureGate;
    final bool isPlus = gate.isPlus;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (subState.hasBillingProblem) ...[
            _LifecycleBanner(
              icon: Icons.warning_amber_rounded,
              borderColor: colors.danger,
              title: 'Billing problem — grace period active',
              message:
                  'We could not process your renewal. Update your payment method on Google Play to keep PekSoft Plus uninterrupted.',
              actionLabel: 'Fix Payment',
              onAction: () => _launchManageSubscription(
                context,
                subState.manageSubscriptionUri,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ] else if (subState.isExpired) ...[
            _LifecycleBanner(
              icon: Icons.lock_clock_rounded,
              borderColor: colors.accent,
              title: 'Subscription expired',
              message:
                  'Your saved favourites, collections, and song history are safe — nothing was deleted. Plus extras are locked until you renew.',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: isPlus ? colors.accent : colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gate.isPaidPlus
                      ? 'PekSoft Plus'
                      : isPlus
                      ? 'PekSoft Plus (24h Pass)'
                      : 'Free Plan',
                  style: AppTypography.h2.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  gate.isPaidPlus
                      ? _paidSubtitle(entitlement)
                      : isPlus
                      ? 'Temporary ad-free & Plus convenience pass active.'
                      : 'Up to ${gate.maxFavourites ?? 30} favourites, ${gate.maxCollections ?? 2} custom collections, ad-supported.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (subState.statusMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              subState.statusMessage!,
              style: AppTypography.bodySmall.copyWith(color: colors.accent),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (!gate.isPaidPlus)
            PrimaryButton(
              label: subState.isExpired ? 'Renew Plus' : 'Upgrade to Plus',
              icon: Icons.workspace_premium_rounded,
              onPressed: () => context.push('/paywall'),
            )
          else ...[
            PrimaryButton(
              label: 'Manage Subscription',
              icon: Icons.open_in_new_rounded,
              onPressed: () => _launchManageSubscription(
                context,
                subState.manageSubscriptionUri,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: AppSpacing.touchTarget,
              child: OutlinedButton(
                onPressed: () => context.push('/paywall'),
                child: const Text('Change Plan'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: AppSpacing.touchTarget,
            child: TextButton(
              onPressed: subState.isProcessing ? null : vm.restorePurchases,
              child: const Text('Restore Purchases'),
            ),
          ),
        ],
      ),
    );
  }

  static String _paidSubtitle(Entitlement entitlement) {
    final String sourceLabel = switch (entitlement.source) {
      EntitlementSource.googlePlay => 'Google Play',
      EntitlementSource.paystack => 'Paystack',
      EntitlementSource.promo => 'Promo',
      EntitlementSource.rewardedAd => 'Rewarded Ad',
      EntitlementSource.none => 'Account',
    };
    if (entitlement.status == EntitlementStatus.grace) {
      return 'Grace period ($sourceLabel) — please update your payment method.';
    }
    return 'Active · Managed via $sourceLabel';
  }
}

class _LifecycleBanner extends StatelessWidget {
  const _LifecycleBanner({
    required this.icon,
    required this.borderColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color borderColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: borderColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: AppSpacing.touchTarget,
              child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ),
          ],
        ],
      ),
    );
  }
}
