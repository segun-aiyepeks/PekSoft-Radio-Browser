import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

class QualityBadge extends StatelessWidget {
  const QualityBadge({
    super.key,
    required this.codec,
    required this.bitrateKbps,
    this.isHls = false,
  });

  final String codec;
  final int bitrateKbps;
  final bool isHls;

  String get _label {
    final cleanCodec = codec.trim().isEmpty ? 'STREAM' : codec.trim();
    final parts = <String>[cleanCodec];
    if (bitrateKbps > 0) {
      parts.add('${bitrateKbps}k');
    }
    if (isHls) {
      parts.add('HLS');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: 'Audio quality $_label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          _label,
          style: AppTypography.caption.copyWith(color: colors.textMuted),
        ),
      ),
    );
  }
}
