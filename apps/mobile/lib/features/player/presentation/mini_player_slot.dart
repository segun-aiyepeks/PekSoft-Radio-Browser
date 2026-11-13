import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Persistent mini-player slot shown above the bottom navigation bar.
/// Synced with [mockSessionController] for UI-only play/pause; full player
/// screen and playback states arrive in Milestone 1.4.
class MiniPlayerSlot extends StatelessWidget {
  const MiniPlayerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        final MockStation station = mockSessionController.currentStation;
        final bool isPlaying =
            mockSessionController.playbackStatus == MockPlaybackStatus.playing;

        return Semantics(
          container: true,
          label:
              'Mini player: ${station.name}, ${isPlaying ? 'playing' : 'paused'}',
          child: InkWell(
            onTap: () => context.push('/station/${station.id}'),
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
                  StationLogo(
                    stationName: station.name,
                    faviconUrl: station.faviconUrl,
                    hasLogo:
                        station.faviconUrl != null &&
                        station.faviconUrl!.isNotEmpty,
                    size: AppSpacing.s2xl + AppSpacing.sm,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          isPlaying
                              ? 'Playing · ${station.country}'
                              : 'Paused · Tap play to listen',
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
                    toggled: isPlaying,
                    label: isPlaying ? 'Pause mini player' : 'Play mini player',
                    child: SizedBox(
                      width: AppSpacing.touchTarget,
                      height: AppSpacing.touchTarget,
                      child: IconButton(
                        onPressed: mockSessionController.togglePlayPause,
                        style: IconButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: colors.onAccent,
                        ),
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
