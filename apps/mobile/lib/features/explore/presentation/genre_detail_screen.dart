import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/genre_detail_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/presentation/station_list_tile.dart';

class GenreDetailScreen extends ConsumerWidget {
  const GenreDetailScreen({super.key, required this.genreName});

  final String genreName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final String genreId = genreName.trim().toLowerCase();
    final AsyncValue<GenreDetailState> stateAsync = ref.watch(
      genreDetailViewModelProvider(genreId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(genreName)),
      body: stateAsync.when(
        loading: () => const SkeletonList(itemCount: 6),
        error: (Object error, StackTrace _) => ErrorState(
          title: 'Could not load genre',
          message: error.toString(),
          onRetry: () => ref
              .read(genreDetailViewModelProvider(genreId).notifier)
              .refresh(),
        ),
        data: (GenreDetailState state) {
          if (state.error != null && state.stations.isEmpty) {
            return ErrorState(
              title: 'Could not load genre',
              message: state.error!.message,
              onRetry: () => ref
                  .read(genreDetailViewModelProvider(genreId).notifier)
                  .refresh(),
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${state.stations.length} stations',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              state.workingNowOnly
                                  ? 'Showing working stations only'
                                  : 'Showing all stations',
                              style: AppTypography.caption.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        toggled: state.workingNowOnly,
                        label: 'Working stations only',
                        child: Switch(
                          value: state.workingNowOnly,
                          onChanged: (_) => ref
                              .read(
                                genreDetailViewModelProvider(genreId).notifier,
                              )
                              .toggleWorkingNow(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.stations.isEmpty)
                EmptyState(
                  title: 'No $genreName stations',
                  message:
                      'Try toggling Working now off to include offline stations.',
                  icon: Icons.music_off_rounded,
                  actionLabel: state.workingNowOnly
                      ? 'Show all stations'
                      : null,
                  onAction: state.workingNowOnly
                      ? () => ref
                            .read(
                              genreDetailViewModelProvider(genreId).notifier,
                            )
                            .toggleWorkingNow()
                      : null,
                )
              else
                for (final Station station in state.stations)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: StationListTile(station: station),
                  ),
            ],
          );
        },
      ),
    );
  }
}
