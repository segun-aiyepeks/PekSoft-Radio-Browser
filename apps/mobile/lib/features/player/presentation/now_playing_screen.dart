import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/utils/country_flag.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/report_station_sheet.dart';
import 'package:peksoft_radio/features/player/presentation/sleep_timer_sheet.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/presentation/station_list_tile.dart';

/// Full Now Playing screen with artwork, ICY track title, play/pause,
/// favourite, sleep timer, share, report sheet, quality badge, similar
/// stations, and a dev-only playback state switcher (`kDebugMode`).
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final PlayerState playerState = ref.watch(playbackViewModelProvider);
    final PlaybackState playback = playerState.playback;
    final Station? station = playback.currentStation;

    if (station == null) {
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
          title: Text(
            'NOW PLAYING',
            style: AppTypography.caption.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: const EmptyState(
          icon: Icons.radio_rounded,
          title: 'No station selected',
          message:
              'Pick a radio station from Home, Explore, or Search to start listening.',
        ),
      );
    }

    final PlaybackStatus status = playback.status;
    final bool isFav = playerState.isFavourite;
    final int? sleepMinutes = playback.sleepTimerRemaining?.inMinutes;
    final List<Station> similar = playerState.similarStations;
    final String flag = countryFlagEmoji(station.countryCode);
    final PlayerViewModel notifier = ref.read(
      playbackViewModelProvider.notifier,
    );

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
              '$flag ${station.countryName}',
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
                        'Share link copied: https://peksoft.radio/station/${station.id}',
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
          if (kDebugMode)
            _DevPlaybackStateSwitcher(
              currentStatus: status,
              onSelectStatus: (PlaybackStatus s) =>
                  notifier.setPlaybackStatus(s),
            ),
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
                    hasLogo: !station.usesFallbackLogo,
                    size: AppSpacing.s3xl * 3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  station.name,
                  textAlign: TextAlign.center,
                  style: AppTypography.h1.copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  playback.icyTitle ??
                      (station.language.isNotEmpty
                          ? 'Live Broadcast · ${station.language}'
                          : 'Live Broadcast'),
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
                  errorMessage: playback.error?.userMessage,
                  onRetry: () => notifier.playStation(station),
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
                          onPressed: notifier.toggleFavourite,
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav ? colors.accent : colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      toggled: status == PlaybackStatus.playing,
                      label: status == PlaybackStatus.playing
                          ? 'Pause ${station.name}'
                          : 'Play ${station.name}',
                      child: SizedBox(
                        width: AppSpacing.s3xl + AppSpacing.lg,
                        height: AppSpacing.s3xl + AppSpacing.lg,
                        child: IconButton.filled(
                          onPressed: notifier.togglePlayPause,
                          style: IconButton.styleFrom(
                            backgroundColor: colors.accent,
                            foregroundColor: colors.onAccent,
                          ),
                          icon: Icon(
                            status == PlaybackStatus.playing
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
                            content: Text(
                              'Share link copied: https://peksoft.radio/station/${station.id}',
                            ),
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
          if (similar.isNotEmpty) ...[
            const SectionHeader(title: 'Similar stations'),
            for (final Station item in similar)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: StationListTile(station: item),
              ),
          ],
        ],
      ),
    );
  }
}

class _PlaybackStatusBanner extends StatelessWidget {
  const _PlaybackStatusBanner({
    required this.status,
    this.errorMessage,
    required this.onRetry,
    required this.onReport,
  });

  final PlaybackStatus status;
  final String? errorMessage;
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
      PlaybackStatus.playing => (
        icon: Icons.graphic_eq_rounded,
        title: 'LIVE · Streaming',
        subtitle: 'Audio stream active',
        tone: colors.success,
        showSpinner: false,
        showActions: false,
      ),
      PlaybackStatus.paused => (
        icon: Icons.pause_circle_outline_rounded,
        title: 'Paused',
        subtitle: 'Tap play to resume live radio',
        tone: colors.textSecondary,
        showSpinner: false,
        showActions: false,
      ),
      PlaybackStatus.buffering => (
        icon: Icons.hourglass_top_rounded,
        title: 'Buffering stream...',
        subtitle: 'Preparing audio buffer',
        tone: colors.info,
        showSpinner: true,
        showActions: false,
      ),
      PlaybackStatus.reconnecting => (
        icon: Icons.wifi_find_rounded,
        title: 'Reconnecting...',
        subtitle: 'Network hiccup — attempting to restore stream',
        tone: colors.warning,
        showSpinner: true,
        showActions: false,
      ),
      PlaybackStatus.unavailable => (
        icon: Icons.error_outline_rounded,
        title: 'Station unavailable',
        subtitle:
            errorMessage ??
            'This stream did not respond. Try again or pick a similar station below.',
        tone: colors.error,
        showSpinner: false,
        showActions: true,
      ),
      PlaybackStatus.idle => (
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
  const _DevPlaybackStateSwitcher({
    required this.currentStatus,
    required this.onSelectStatus,
  });

  final PlaybackStatus currentStatus;
  final ValueChanged<PlaybackStatus> onSelectStatus;

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
              for (final PlaybackStatus state in PlaybackStatus.values)
                GenreChip(
                  label: state.name,
                  selected: currentStatus == state,
                  onTap: () => onSelectStatus(state),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
