import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Persistent mini-player slot shown above the bottom navigation bar.
/// Synced with [mockSessionController] across all playback states and opens
/// the full Now Playing screen (`/player`) on tap.
class MiniPlayerSlot extends StatelessWidget {
  const MiniPlayerSlot({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        final MockStation station = mockSessionController.currentStation;
        final MockPlaybackStatus status = mockSessionController.playbackStatus;
        final bool isPlaying = status == MockPlaybackStatus.playing;
        final bool isLoading =
            status == MockPlaybackStatus.buffering ||
            status == MockPlaybackStatus.reconnecting;

        final String subtitle = switch (status) {
          MockPlaybackStatus.playing => 'Playing · ${station.country}',
          MockPlaybackStatus.paused => 'Paused · Tap play to listen',
          MockPlaybackStatus.buffering => 'Buffering stream...',
          MockPlaybackStatus.reconnecting => 'Reconnecting...',
          MockPlaybackStatus.unavailable => 'Station unavailable',
          MockPlaybackStatus.idle => 'Tap play to listen',
        };

        return Semantics(
          container: true,
          label: 'Mini player: ${station.name}, $subtitle',
          child: InkWell(
            onTap: () => context.push('/player'),
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
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: status == MockPlaybackStatus.unavailable
                                ? colors.error
                                : colors.textSecondary,
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
                          backgroundColor:
                              status == MockPlaybackStatus.unavailable
                              ? colors.error
                              : colors.accent,
                          foregroundColor: colors.onAccent,
                        ),
                        icon: isLoading
                            ? SizedBox(
                                width: AppSpacing.lg,
                                height: AppSpacing.lg,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onAccent,
                                ),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : status == MockPlaybackStatus.unavailable
                                    ? Icons.refresh_rounded
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
