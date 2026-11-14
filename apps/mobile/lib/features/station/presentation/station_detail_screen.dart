import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/utils/country_flag.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/presentation/station_list_tile.dart';
import 'package:peksoft_radio/features/station/presentation/view_models/station_detail_view_model.dart';

class StationDetailScreen extends ConsumerWidget {
  const StationDetailScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final AsyncValue<StationDetailState> detailAsync = ref.watch(
      stationDetailViewModelProvider(stationId),
    );
    final PlayerState playerState = ref.watch(playerViewModelProvider);

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Station')),
        body: const SkeletonList(itemCount: 4),
      ),
      error: (Object error, StackTrace _) => Scaffold(
        appBar: AppBar(title: const Text('Station')),
        body: ErrorState(
          title: 'Station not found',
          message: error.toString(),
          onRetry: () => ref
              .read(stationDetailViewModelProvider(stationId).notifier)
              .refresh(),
        ),
      ),
      data: (StationDetailState detail) {
        final Station? station = detail.station;
        if (station == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Station')),
            body: ErrorState(
              title: 'Station not found',
              message: detail.error?.message ?? 'Unable to load station.',
              onRetry: () => context.pop(),
              retryLabel: 'Go back',
            ),
          );
        }

        final bool isCurrent =
            playerState.playback.currentStation?.id == station.id;
        final bool isPlaying =
            isCurrent && playerState.playback.status == PlaybackStatus.playing;
        final String flag = countryFlagEmoji(station.countryCode);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              station.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              Semantics(
                button: true,
                toggled: detail.isFavourite,
                label: detail.isFavourite
                    ? 'Remove ${station.name} from favourites'
                    : 'Add ${station.name} to favourites',
                child: SizedBox(
                  width: AppSpacing.touchTarget,
                  height: AppSpacing.touchTarget,
                  child: IconButton(
                    tooltip: detail.isFavourite
                        ? 'Remove favourite'
                        : 'Add favourite',
                    onPressed: () => ref
                        .read(
                          stationDetailViewModelProvider(stationId).notifier,
                        )
                        .toggleFavourite(),
                    icon: Icon(
                      detail.isFavourite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: detail.isFavourite
                          ? colors.accent
                          : colors.textPrimary,
                    ),
                  ),
                ),
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
                          faviconUrl: station.usesFallbackLogo
                              ? null
                              : station.faviconUrl,
                          hasLogo: !station.usesFallbackLogo,
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
                                station.language.isNotEmpty
                                    ? '$flag ${station.countryName} · ${station.language}'
                                    : '$flag ${station.countryName}',
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
                    PrimaryButton(
                      label: isPlaying ? 'Pause Station' : 'Play Station',
                      icon: isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      onPressed: () {
                        final PlayerViewModel player = ref.read(
                          playerViewModelProvider.notifier,
                        );
                        if (isCurrent) {
                          player.togglePlayPause();
                        } else {
                          player.playStation(station);
                        }
                      },
                    ),
                    if (station.genres.isNotEmpty) ...[
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
                          for (final Genre genre in station.genres)
                            GenreChip(
                              label: genre.name,
                              onTap: () => context.push(
                                '/genre/${Uri.encodeComponent(genre.id)}',
                              ),
                            ),
                        ],
                      ),
                    ],
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
                          _MetaRow(
                            label: 'Clicks',
                            value: '${station.clickCount}',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _MetaRow(label: 'Votes', value: '${station.votes}'),
                          if (station.homepage.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            _MetaRow(
                              label: 'Homepage',
                              value: station.homepage,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (detail.similarStations.isNotEmpty) ...[
                const SectionHeader(title: 'Similar stations'),
                for (final Station s in detail.similarStations)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: StationListTile(station: s),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withAlpha(120)),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Text(
          '$label: ',
          style: AppTypography.bodySmall.copyWith(color: colors.textMuted),
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
