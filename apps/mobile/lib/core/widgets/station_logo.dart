import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

/// Displays a station's artwork or a deterministic monogram fallback
/// derived from the station's name and design tokens.
class StationLogo extends StatelessWidget {
  const StationLogo({
    super.key,
    required this.stationName,
    this.faviconUrl,
    this.size = AppSpacing.touchTarget,
    this.hasLogo = false,
  });

  final String stationName;
  final String? faviconUrl;
  final double size;
  final bool hasLogo;

  String get _initials {
    final words = stationName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final palette = [
      colors.accent,
      colors.info,
      colors.success,
      colors.warning,
    ];
    final hash = stationName.codeUnits.fold<int>(0, (acc, c) => acc + c);
    final tint = palette[hash % palette.length];

    return Semantics(
      image: true,
      label: '$stationName logo',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: tint.withValues(alpha: 0.45)),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              _initials,
              style: AppTypography.title.copyWith(
                color: tint,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasLogo && faviconUrl != null && faviconUrl!.isNotEmpty)
              Positioned(
                right: AppSpacing.xxs,
                bottom: AppSpacing.xxs,
                child: Icon(
                  Icons.radio_rounded,
                  size: AppSpacing.md,
                  color: tint.withValues(alpha: 0.8),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
