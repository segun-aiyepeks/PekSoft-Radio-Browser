import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/home/presentation/view_models/home_view_model.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/search/presentation/filters_bottom_sheet.dart';
import 'package:peksoft_radio/features/search/presentation/view_models/search_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/presentation/station_list_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openFilters(BuildContext context, WidgetRef ref) async {
    final SearchState searchState = ref.read(searchViewModelProvider);
    final StationFilterSelection? next = await showStationFiltersSheet(
      context,
      initial: StationFilterSelection.fromDomain(
        searchState.filter,
        sort: searchState.sort,
      ),
    );
    if (next != null && context.mounted) {
      await ref
          .read(searchViewModelProvider.notifier)
          .applyFilter(next.toStationFilter());
      await ref.read(searchViewModelProvider.notifier).setSort(next.sort);
      if (context.mounted) {
        context.push('/search');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final AsyncValue<HomeState> homeAsync = ref.watch(homeViewModelProvider);
    final SearchState searchState = ref.watch(searchViewModelProvider);
    final int activeFilters = StationFilterSelection.fromDomain(
      searchState.filter,
      sort: searchState.sort,
    ).activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PekSoft Radio'),
        actions: [
          Semantics(
            button: true,
            label: 'Search stations',
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push('/search'),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Filter stations',
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: IconButton(
                tooltip: 'Filters',
                icon: Badge(
                  isLabelVisible: activeFilters > 0,
                  label: Text('$activeFilters'),
                  child: const Icon(Icons.tune_rounded),
                ),
                onPressed: () => _openFilters(context, ref),
              ),
            ),
          ),
          if (kDebugMode)
            Semantics(
              button: true,
              label: 'Open component gallery',
              child: SizedBox(
                width: AppSpacing.touchTarget,
                height: AppSpacing.touchTarget,
                child: IconButton(
                  tooltip: 'Component Gallery (Dev)',
                  icon: Icon(Icons.widgets_outlined, color: colors.accent),
                  onPressed: () => context.push('/gallery'),
                ),
              ),
            ),
        ],
      ),
      body: homeAsync.when(
        loading: () => const SkeletonList(itemCount: 6),
        error: (Object error, StackTrace _) => ErrorState(
          title: 'Could not load stations',
          message: error.toString(),
          onRetry: () => ref.read(homeViewModelProvider.notifier).refresh(),
        ),
        data: (HomeState home) {
          if (home.error != null && home.stations.isEmpty) {
            return ErrorState(
              title: 'Could not load stations',
              message: home.error!.message,
              onRetry: () => ref.read(homeViewModelProvider.notifier).refresh(),
            );
          }

          final List<Genre> quickGenres = home.genres.take(6).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(homeViewModelProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Semantics(
                    button: true,
                    label: 'Search radio stations, countries, and genres',
                    child: InkWell(
                      onTap: () => context.push('/search'),
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: AppSpacing.touchTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: colors.textMuted),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Search stations worldwide...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                FilterChipBar(
                  items: [
                    FilterChipItem(
                      id: 'all',
                      label: 'All',
                      selected: home.selectedGenreId == null,
                    ),
                    for (final Genre genre in quickGenres)
                      FilterChipItem(
                        id: genre.id,
                        label: genre.name,
                        selected: home.selectedGenreId == genre.id,
                      ),
                  ],
                  onToggle: (id) {
                    ref
                        .read(homeViewModelProvider.notifier)
                        .selectGenre(id == 'all' ? null : id);
                  },
                ),
                if (home.curatedCollections.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SectionHeader(
                    title: 'Curated collections',
                    actionLabel: 'Explore',
                    onActionTap: () => context.go('/explore'),
                  ),
                  SizedBox(
                    height: 128,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      itemCount: home.curatedCollections.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final Collection col = home.curatedCollections[index];
                        return _CollectionCard(
                          collection: col,
                          onTap: () {
                            if (col.stationIds.isNotEmpty) {
                              context.push('/station/${col.stationIds.first}');
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
                if (home.entitlement.adsEnabled) ...[
                  const SizedBox(height: AppSpacing.md),
                  const AdSlotPlaceholder(),
                ],
                const SizedBox(height: AppSpacing.sm),
                SectionHeader(
                  title: 'Live & working now',
                  actionLabel: '${home.stations.length} stations',
                  onActionTap: () => _openFilters(context, ref),
                ),
                if (home.stations.isEmpty)
                  EmptyState(
                    title: 'No matching stations',
                    message: 'Try clearing the genre filter or refreshing.',
                    icon: Icons.radio_rounded,
                    actionLabel: 'Reset filters',
                    onAction: () => ref
                        .read(homeViewModelProvider.notifier)
                        .selectGenre(null),
                  )
                else
                  for (final Station station in home.stations.take(20))
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: StationListTile(station: station),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, required this.onTap});

  final Collection collection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final int count = collection.stationIds.length;
    return Semantics(
      button: true,
      label: '${collection.title}, $count stations',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            width: 224,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.title.copyWith(color: colors.accent),
                ),
                const SizedBox(height: AppSpacing.xs),
                Expanded(
                  child: Text(
                    collection.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '$count stations',
                  style: AppTypography.caption.copyWith(
                    color: colors.textMuted,
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
