import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/player/presentation/report_station_sheet.dart';
import 'package:peksoft_radio/features/player/presentation/sleep_timer_sheet.dart';
import 'package:peksoft_radio/features/station/presentation/mock_station_tile.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Full Now Playing screen with artwork, track title, play/pause, favourite,
/// sleep timer, share, report sheet, quality badge, similar stations, and a
/// dev-only playback state switcher (`kDebugMode`).
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        final MockStation station = mockSessionController.currentStation;
        final MockPlaybackStatus status = mockSessionController.playbackStatus;
        final bool isFav = mockSessionController.isFavourite(station.id);
        final int? sleepMinutes = mockSessionController.sleepTimerMinutes;
        final List<MockStation> similar = getMockSimilarStations(station);

        return Scaffold(
          appBar: AppBar(
            leading: Semantics(
              button: true,
              label: 'Close now playing',
              child: SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            title: Column(
              children: [
                Text(
                  'NOW PLAYING',
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${station.flagEmoji} ${station.country}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              Semantics(
                button: true,
                label: 'Share ${station.name}',
                child: SizedBox(
                  width: AppSpacing.touchTarget,
                  height: AppSpacing.touchTarget,
                  child: IconButton(
                    tooltip: 'Share',
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Share link copied (mock): https://peksoft.radio/station/${station.id}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s2xl),
            children: [
              if (kDebugMode) _DevPlaybackStateSwitcher(currentStatus: status),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        border: Border.all(color: colors.border),
                      ),
                      child: StationLogo(
                        stationName: station.name,
                        faviconUrl: station.faviconUrl,
                        hasLogo:
                            station.faviconUrl != null &&
                            station.faviconUrl!.isNotEmpty,
                        size: AppSpacing.s3xl * 3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      station.name,
                      textAlign: TextAlign.center,
                      style: AppTypography.h1.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      station.currentTrack ??
                          'Live Broadcast · ${station.language}',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        QualityBadge(
                          codec: station.codec,
                          bitrateKbps: station.bitrateKbps,
                          isHls: station.isHls,
                        ),
                        if (sleepMinutes != null)
                          GenreChip(
                            label: 'Sleep: ${sleepMinutes}m',
                            selected: true,
                            onTap: () => showSleepTimerSheet(context),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PlaybackStatusBanner(
                      status: status,
                      onRetry: () => mockSessionController.setPlaybackStatus(
                        MockPlaybackStatus.playing,
                      ),
                      onReport: () => showReportStationSheet(context, station),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Semantics(
                          button: true,
                          toggled: isFav,
                          label: isFav
                              ? 'Remove ${station.name} from favourites'
                              : 'Add ${station.name} to favourites',
                          child: SizedBox(
                            width: AppSpacing.touchTarget,
                            height: AppSpacing.touchTarget,
                            child: IconButton(
                              tooltip: isFav ? 'Unfavourite' : 'Favourite',
                              onPressed: () => mockSessionController
                                  .toggleFavourite(station.id),
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isFav
                                    ? colors.accent
                                    : colors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          toggled: status == MockPlaybackStatus.playing,
                          label: status == MockPlaybackStatus.playing
                              ? 'Pause ${station.name}'
                              : 'Play ${station.name}',
                          child: SizedBox(
                            width: AppSpacing.s3xl + AppSpacing.lg,
                            height: AppSpacing.s3xl + AppSpacing.lg,
                            child: IconButton.filled(
                              onPressed: mockSessionController.togglePlayPause,
                              style: IconButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: colors.onAccent,
                              ),
                              icon: Icon(
                                status == MockPlaybackStatus.playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: AppSpacing.s2xl,
                              ),
                            ),
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: sleepMinutes == null
                              ? 'Open sleep timer'
                              : 'Sleep timer active: $sleepMinutes minutes',
                          child: SizedBox(
                            width: AppSpacing.touchTarget,
                            height: AppSpacing.touchTarget,
                            child: IconButton(
                              tooltip: 'Sleep Timer',
                              onPressed: () => showSleepTimerSheet(context),
                              icon: Badge(
                                isLabelVisible: sleepMinutes != null,
                                label: Text('${sleepMinutes ?? 0}m'),
                                child: Icon(
                                  Icons.bedtime_outlined,
                                  color: sleepMinutes != null
                                      ? colors.accent
                                      : colors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PlayerActionButton(
                          icon: Icons.flag_outlined,
                          label: 'Report',
                          onTap: () => showReportStationSheet(context, station),
                        ),
                        _PlayerActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Shared ${station.name} (mock)'),
                              ),
                            );
                          },
                        ),
                        _PlayerActionButton(
                          icon: Icons.info_outline_rounded,
                          label: 'Details',
                          onTap: () => context.push('/station/${station.id}'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SectionHeader(title: 'Similar stations'),
              for (final MockStation item in similar)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: MockStationTile(station: item),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlaybackStatusBanner extends StatelessWidget {
  const _PlaybackStatusBanner({
    required this.status,
    required this.onRetry,
    required this.onReport,
  });

  final MockPlaybackStatus status;
  final VoidCallback onRetry;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final ({
      IconData icon,
      String title,
      String subtitle,
      Color tone,
      bool showSpinner,
      bool showActions,
    })
    data = switch (status) {
      MockPlaybackStatus.playing => (
        icon: Icons.graphic_eq_rounded,
        title: 'LIVE · Streaming',
        subtitle: 'Audio stream active (Phase 1 mock)',
        tone: colors.success,
        showSpinner: false,
        showActions: false,
      ),
      MockPlaybackStatus.paused => (
        icon: Icons.pause_circle_outline_rounded,
        title: 'Paused',
        subtitle: 'Tap play to resume live radio',
        tone: colors.textSecondary,
        showSpinner: false,
        showActions: false,
      ),
      MockPlaybackStatus.buffering => (
        icon: Icons.hourglass_top_rounded,
        title: 'Buffering stream...',
        subtitle: 'Preparing audio buffer',
        tone: colors.info,
        showSpinner: true,
        showActions: false,
      ),
      MockPlaybackStatus.reconnecting => (
        icon: Icons.wifi_find_rounded,
        title: 'Reconnecting...',
        subtitle: 'Network hiccup — attempting to restore stream',
        tone: colors.warning,
        showSpinner: true,
        showActions: false,
      ),
      MockPlaybackStatus.unavailable => (
        icon: Icons.error_outline_rounded,
        title: 'Station unavailable',
        subtitle: 'This stream did not respond. Try again or report it.',
        tone: colors.error,
        showSpinner: false,
        showActions: true,
      ),
      MockPlaybackStatus.idle => (
        icon: Icons.radio_rounded,
        title: 'Ready to play',
        subtitle: 'Tap play to start listening',
        tone: colors.textSecondary,
        showSpinner: false,
        showActions: false,
      ),
    };

    return Semantics(
      liveRegion: true,
      label: '${data.title}. ${data.subtitle}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: data.tone),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (data.showSpinner)
                  SizedBox(
                    width: AppSpacing.lg,
                    height: AppSpacing.lg,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: data.tone,
                    ),
                  )
                else
                  Icon(data.icon, color: data.tone),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: AppTypography.title.copyWith(color: data.tone),
                      ),
                      Text(
                        data.subtitle,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data.showActions) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    height: AppSpacing.touchTarget,
                    child: OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.touchTarget,
                    child: TextButton.icon(
                      onPressed: onReport,
                      icon: const Icon(Icons.flag_outlined),
                      label: const Text('Report broken'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerActionButton extends StatelessWidget {
  const _PlayerActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchTarget,
            minHeight: AppSpacing.touchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: colors.textSecondary),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary,
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

class _DevPlaybackStateSwitcher extends StatelessWidget {
  const _DevPlaybackStateSwitcher({required this.currentStatus});

  final MockPlaybackStatus currentStatus;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dev State Switcher (Preview Playback States)',
            style: AppTypography.caption.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final MockPlaybackStatus state in MockPlaybackStatus.values)
                GenreChip(
                  label: state.name,
                  selected: currentStatus == state,
                  onTap: () => mockSessionController.setPlaybackStatus(state),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
