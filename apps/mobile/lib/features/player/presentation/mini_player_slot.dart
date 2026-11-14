import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Persistent mini-player slot shown above the bottom navigation bar.
/// Synced with [playbackViewModelProvider] across all playback states and opens
/// the full Now Playing screen (`/player`) on tap.
class MiniPlayerSlot extends ConsumerWidget {
  const MiniPlayerSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final PlayerState playerState = ref.watch(playbackViewModelProvider);
    final PlaybackState playback = playerState.playback;
    final Station? station = playback.currentStation;
    final PlaybackStatus status = playback.status;
    final bool isPlaying = status == PlaybackStatus.playing;
    final bool isLoading =
        status == PlaybackStatus.buffering ||
        status == PlaybackStatus.reconnecting;

    final String title = station?.name ?? 'PekSoft Radio';
    final String subtitle = station == null
        ? 'Tap a station to listen'
        : switch (status) {
            PlaybackStatus.playing =>
              playback.icyTitle ?? 'Playing · ${station.countryName}',
            PlaybackStatus.paused => 'Paused · Tap play to listen',
            PlaybackStatus.buffering => 'Buffering stream...',
            PlaybackStatus.reconnecting => 'Reconnecting...',
            PlaybackStatus.unavailable => 'Station unavailable',
            PlaybackStatus.idle => 'Tap play to listen',
          };

    return Semantics(
      container: true,
      label: 'Mini player: $title, $subtitle',
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
                stationName: title,
                faviconUrl: station?.faviconUrl,
                hasLogo: !(station?.usesFallbackLogo ?? true),
                size: AppSpacing.s2xl + AppSpacing.sm,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                        color: status == PlaybackStatus.unavailable
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
                    onPressed: station == null
                        ? null
                        : ref
                              .read(playbackViewModelProvider.notifier)
                              .togglePlayPause,
                    style: IconButton.styleFrom(
                      backgroundColor: status == PlaybackStatus.unavailable
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
                                : status == PlaybackStatus.unavailable
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
  }
}
