import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

class GenreChip extends StatelessWidget {
  const GenreChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = selected
        ? colors.accent.withValues(alpha: 0.18)
        : colors.surfaceMuted;
    final borderColor = selected ? colors.accent : colors.border;
    final textColor = selected ? colors.accent : colors.textSecondary;

    final chipBody = Container(
      constraints: BoxConstraints(
        minHeight: compact ? AppSpacing.xl : AppSpacing.touchTarget,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: (compact ? AppTypography.caption : AppTypography.label)
                  .copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: label, child: chipBody);
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.full),
        child: chipBody,
      ),
    );
  }
}
