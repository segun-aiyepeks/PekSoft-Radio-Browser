import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Paywall screen (UI-only in Phase 1): Monthly/Annual toggle, benefits,
/// restore purchases, terms/privacy links, and visible close button.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isAnnual = true;

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
      title: 'Full Song History',
      subtitle: 'Never lose track of a song you heard on air.',
    ),
    (
      icon: Icons.cloud_sync_rounded,
      title: 'Cross-Device Sync',
      subtitle: 'Keep your library in sync across Android and Web.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PekSoft Pro'),
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
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Upgrade your radio experience',
            style: AppTypography.h1.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Mock Phase 1 paywall — no real billing occurs.',
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PlanCard(
                  title: 'Monthly',
                  price: '\$2.99 / mo',
                  badge: null,
                  selected: !_isAnnual,
                  onTap: () => setState(() => _isAnnual = false),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PlanCard(
                  title: 'Annual',
                  price: '\$23.99 / yr',
                  badge: 'Save 33%',
                  selected: _isAnnual,
                  onTap: () => setState(() => _isAnnual = true),
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
            label: _isAnnual
                ? 'Start Annual Pro (Mock)'
                : 'Start Monthly Pro (Mock)',
            icon: Icons.workspace_premium_rounded,
            onPressed: () {
              mockSessionController.setProMock(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PekSoft Pro activated (mock)!')),
              );
              context.pop();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restore purchases checked (mock).'),
                    ),
                  );
                },
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
