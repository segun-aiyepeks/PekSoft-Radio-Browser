import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/station/presentation/mock_station_tile.dart';
import 'package:peksoft_radio/mock/mock.dart';

class StationDetailScreen extends StatelessWidget {
  const StationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final MockStation? station = getMockStationById(stationId);

    if (station == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Station')),
        body: ErrorState(
          title: 'Station not found',
          message: 'This mock station could not be loaded.',
          onRetry: () => context.pop(),
          retryLabel: 'Go back',
        ),
      );
    }

    final List<MockStation> similar = getMockSimilarStations(station);

    return Scaffold(
      appBar: AppBar(
        title: Text(station.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          ListenableBuilder(
            listenable: mockSessionController,
            builder: (context, _) {
              final bool isFav = mockSessionController.isFavourite(station.id);
              return Semantics(
                button: true,
                toggled: isFav,
                label: isFav
                    ? 'Remove ${station.name} from favourites'
                    : 'Add ${station.name} to favourites',
                child: SizedBox(
                  width: AppSpacing.touchTarget,
                  height: AppSpacing.touchTarget,
                  child: IconButton(
                    tooltip: isFav ? 'Remove favourite' : 'Add favourite',
                    onPressed: () =>
                        mockSessionController.toggleFavourite(station.id),
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFav ? colors.accent : colors.textPrimary,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s2xl),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StationLogo(
                      stationName: station.name,
                      faviconUrl: station.faviconUrl,
                      hasLogo:
                          station.faviconUrl != null &&
                          station.faviconUrl!.isNotEmpty,
                      size: AppSpacing.s3xl + AppSpacing.md,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: AppTypography.h2.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${station.flagEmoji} ${station.country} · ${station.language}',
                            style: AppTypography.body.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              QualityBadge(
                                codec: station.codec,
                                bitrateKbps: station.bitrateKbps,
                                isHls: station.isHls,
                              ),
                              _StatusChip(
                                label: station.isWorking
                                    ? 'Working now'
                                    : 'Unavailable',
                                color: station.isWorking
                                    ? colors.success
                                    : colors.error,
                              ),
                              _StatusChip(
                                label: station.isHttps ? 'HTTPS' : 'HTTP',
                                color: station.isHttps
                                    ? colors.info
                                    : colors.warning,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                if (station.currentTrack != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.graphic_eq_rounded,
                          color: colors.accent,
                          size: AppSpacing.xl,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Now on air (Mock)',
                                style: AppTypography.caption.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                              Text(
                                station.currentTrack!,
                                style: AppTypography.title.copyWith(
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                ListenableBuilder(
                  listenable: mockSessionController,
                  builder: (context, _) {
                    final bool isPlaying =
                        mockSessionController.currentStation.id == station.id &&
                        mockSessionController.playbackStatus ==
                            MockPlaybackStatus.playing;
                    return PrimaryButton(
                      label: isPlaying ? 'Pause Station' : 'Play Station',
                      icon: isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: () {
                        if (mockSessionController.currentStation.id ==
                            station.id) {
                          mockSessionController.togglePlayPause();
                        } else {
                          mockSessionController.playStation(station);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Genres',
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final String genre in station.genres)
                      GenreChip(
                        label: genre,
                        onTap: () => context.push(
                          '/genre/${Uri.encodeComponent(genre)}',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(
                        label: 'Votes',
                        value: '${station.votes} community votes',
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _DetailRow(
                        label: 'Clicks',
                        value: '${station.clickCount} recent plays',
                      ),
                      if (station.homepage.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _DetailRow(label: 'Homepage', value: station.homepage),
                      ],
                    ],
                  ),
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
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: colors.textMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}
