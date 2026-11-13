import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';

/// Persistent offline status banner built strictly from design tokens.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Offline mode active. Showing cached favourites and recents.',
      child: Material(
        color: colors.surfaceElevated,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.warning)),
          ),
          child: Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: colors.warning, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'You\'re offline · Cached library available',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onRetry != null)
                Semantics(
                  button: true,
                  label: 'Reconnect',
                  child: SizedBox(
                    height: AppSpacing.touchTarget,
                    child: TextButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
