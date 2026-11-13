import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

/// Persistent mini-player slot shown above the bottom navigation bar.
/// Full playback controls & states are built in Milestone 1.4.
class MiniPlayerSlot extends StatefulWidget {
  const MiniPlayerSlot({super.key});

  @override
  State<MiniPlayerSlot> createState() => _MiniPlayerSlotState();
}

class _MiniPlayerSlotState extends State<MiniPlayerSlot> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Semantics(
      container: true,
      label:
          'Mini player: Wazobia FM Lagos, ${_isPlaying ? 'playing' : 'paused'}',
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const StationLogo(
              stationName: 'Wazobia FM: Lagos',
              size: AppSpacing.s2xl + AppSpacing.sm,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wazobia FM: Lagos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    _isPlaying ? 'Playing · Nigeria' : 'Tap play to listen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              toggled: _isPlaying,
              label: _isPlaying ? 'Pause mini player' : 'Play mini player',
              child: SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: IconButton(
                  onPressed: () => setState(() => _isPlaying = !_isPlaying),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.onAccent,
                  ),
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
