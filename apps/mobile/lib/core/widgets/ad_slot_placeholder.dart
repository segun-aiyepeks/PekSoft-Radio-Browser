import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

enum AdSlotVariant { banner, nativeCard }

class AdSlotPlaceholder extends StatelessWidget {
  const AdSlotPlaceholder({
    super.key,
    this.variant = AdSlotVariant.banner,
    this.onRemoveAdsTap,
  });

  final AdSlotVariant variant;
  final VoidCallback? onRemoveAdsTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isNative = variant == AdSlotVariant.nativeCard;

    return Semantics(
      container: true,
      label: isNative
          ? 'Sponsored native ad placeholder'
          : 'Sponsored banner ad placeholder',
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadii.sm),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'AD',
                style: AppTypography.caption.copyWith(
                  color: colors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isNative
                        ? 'Sponsored · Native Ad Slot'
                        : 'Sponsored · Adaptive Banner Slot',
                    style: AppTypography.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  if (isNative) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'AdMob placeholder — never blocks playback controls.',
                      style: AppTypography.caption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onRemoveAdsTap != null)
              Semantics(
                button: true,
                label: 'Remove ads with Plus',
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchTarget,
                    minHeight: AppSpacing.touchTarget,
                  ),
                  child: TextButton(
                    onPressed: onRemoveAdsTap,
                    child: Text(
                      'Remove',
                      style: AppTypography.label.copyWith(color: colors.accent),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
