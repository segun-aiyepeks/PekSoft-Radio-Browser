import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/home/presentation/view_models/home_view_model.dart';
import 'package:peksoft_radio/features/library/domain/collection.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/search/presentation/filters_bottom_sheet.dart';
import 'package:peksoft_radio/features/search/presentation/view_models/search_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

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
    final LibraryState? libraryState = ref.watch(libraryViewModelProvider).value;
    final SearchState searchState = ref.watch(searchViewModelProvider);
    final int activeFilters = StationFilterSelection.fromDomain(
      searchState.filter,
      sort: searchState.sort,
    ).activeFilterCount;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.lg,
        title: Row(
          children: [
            const PekSoftLogoMark(size: 32),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'PekSoft Radio Browser',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
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
        ],
      ),
      body: homeAsync.when(
        loading: () => const Center(
          child: PekSoftSignalLoader(label: 'Searching for signal…'),
        ),
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

          final List<Station> favourites =
              libraryState?.favourites ?? const <Station>[];
          final List<Collection> savedCollections = _mergeCollections(
            userCollections: libraryState?.collections ?? const <Collection>[],
            curatedCollections: home.curatedCollections,
          );
          final List<Genre> shelfGenres = home.genres.take(8).toList();

          return RefreshIndicator(
            onRefresh: () async {
              for (final Genre g in shelfGenres) {
                ref.invalidate(homeGenreStationsProvider(g.id));
              }
              await ref.read(homeViewModelProvider.notifier).refresh();
            },
            child: CustomScrollView(
              slivers: <Widget>[
                // Search Bar + Shuffle Stations button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
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
                                borderRadius: BorderRadius.circular(
                                  AppRadii.full,
                                ),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    color: colors.textMuted,
                                  ),
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
                        const SizedBox(height: AppSpacing.sm),
                        Semantics(
                          button: true,
                          label: 'Shuffle Stations, play a random live station',
                          child: Material(
                            color: colors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              side: BorderSide(color: colors.border),
                            ),
                            child: InkWell(
                              onTap: () => ref
                                  .read(playbackViewModelProvider.notifier)
                                  .playSurpriseMe(),
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: AppSpacing.touchTarget,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: colors.accent,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.sm,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.shuffle_rounded,
                                          size: 18,
                                          color: colors.onAccent,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Shuffle Stations',
                                              style: AppTypography.label
                                                  .copyWith(
                                                    color: colors.textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            Text(
                                              'Play a random live station worldwide',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: colors.textSecondary,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: colors.accentText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Favourites shelf at the very top when user has favourites
                if (favourites.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _StationShelf(
                      title: 'Favourites',
                      actionLabel: 'See more',
                      onActionTap: () => context.go('/library'),
                      stations: favourites,
                    ),
                  ),

                // All Stations shelf (Spotify-style horizontal scrollable cards)
                if (home.stations.isEmpty)
                  SliverToBoxAdapter(
                    child: EmptyState(
                      title: 'No matching stations',
                      message: 'Pull down to refresh live stations.',
                      icon: Icons.radio_rounded,
                      actionLabel: 'Refresh',
                      onAction: () =>
                          ref.read(homeViewModelProvider.notifier).refresh(),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _StationShelf(
                      title: 'All',
                      actionLabel: 'See more',
                      onActionTap: () => context.push('/search'),
                      stations: home.stations.take(20).toList(growable: false),
                    ),
                  ),

                // Ad slot (clean solid Material surface)
                if (home.entitlement.adsEnabled)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm),
                      child: AdSlotPlaceholder(),
                    ),
                  ),

                // Genre horizontal shelves (Afrobeats, Highlife, Pop, etc.)
                SliverList.builder(
                  itemCount: shelfGenres.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Genre genre = shelfGenres[index];
                    return _GenreStationShelf(
                      genre: genre,
                      fallbackStations: home.stations
                          .where(
                            (Station s) => s.genres.any(
                              (Genre g) => g.id == genre.id,
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),

                // Saved Collections at the bottom
                if (savedCollections.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        SectionHeader(
                          title: 'Saved collections',
                          actionLabel: 'See more',
                          onActionTap: () => context.go('/library'),
                        ),
                        SizedBox(
                          height: 128,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: savedCollections.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final Collection col = savedCollections[index];
                              return _CollectionCard(
                                collection: col,
                                onTap: () {
                                  if (col.stationIds.isNotEmpty) {
                                    context.push(
                                      '/station/${col.stationIds.first}',
                                    );
                                  } else {
                                    context.go('/library');
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                // Footer
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Text(
                      '© ${DateTime.now().year} developed by aiyepeks',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: colors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static List<Collection> _mergeCollections({
    required List<Collection> userCollections,
    required List<Collection> curatedCollections,
  }) {
    final Map<String, Collection> merged = <String, Collection>{};
    for (final Collection c in userCollections) {
      merged[c.id] = c;
    }
    for (final Collection c in curatedCollections) {
      merged.putIfAbsent(c.id, () => c);
    }
    return merged.values.toList(growable: false);
  }
}

class _GenreStationShelf extends ConsumerWidget {
  const _GenreStationShelf({
    required this.genre,
    required this.fallbackStations,
  });

  final Genre genre;
  final List<Station> fallbackStations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Station>> stationsAsync = ref.watch(
      homeGenreStationsProvider(genre.id),
    );
    final List<Station> stations = stationsAsync.when(
      data: (List<Station> list) =>
          list.isNotEmpty ? list : fallbackStations,
      loading: () => fallbackStations,
      error: (_, _) => fallbackStations,
    );

    if (stations.isEmpty && !stationsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    if (stations.isEmpty && stationsAsync.isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          SectionHeader(
            title: genre.name,
            actionLabel: 'See more',
            onActionTap: () =>
                context.push('/genre/${Uri.encodeComponent(genre.id)}'),
          ),
          SizedBox(
            height: 204,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, _) => Container(
                width: 152,
                decoration: BoxDecoration(
                  color: context.appColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: context.appColors.border),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return _StationShelf(
      title: genre.name,
      actionLabel: 'See more',
      onActionTap: () =>
          context.push('/genre/${Uri.encodeComponent(genre.id)}'),
      stations: stations,
    );
  }
}

class _StationShelf extends StatelessWidget {
  const _StationShelf({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    required this.stations,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final List<Station> stations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        SectionHeader(
          title: title,
          actionLabel: actionLabel,
          onActionTap: onActionTap,
        ),
        SizedBox(
          height: 204,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: stations.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              return _SpotifyStationCard(station: stations[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _SpotifyStationCard extends ConsumerWidget {
  const _SpotifyStationCard({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final PlayerState playerState = ref.watch(playerViewModelProvider);
    final bool isCurrent =
        playerState.playback.currentStation?.id == station.id;
    final bool isPlaying =
        isCurrent && playerState.playback.status == PlaybackStatus.playing;

    return Semantics(
      button: true,
      label: '${station.name}, ${station.countryName}',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(
            color: isCurrent ? colors.accent : colors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final notifier = ref.read(playerViewModelProvider.notifier);
            if (isCurrent) {
              notifier.togglePlayPause();
            } else {
              notifier.playStation(station);
            }
          },
          onLongPress: () => context.push('/station/${station.id}'),
          child: SizedBox(
            width: 152,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Center(
                        child: StationLogo(
                          stationName: station.name,
                          faviconUrl: station.usesFallbackLogo
                              ? null
                              : station.faviconUrl,
                          hasLogo: !station.usesFallbackLogo,
                          genres: station.genres.map((g) => g.id).toList(),
                          size: 124,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? colors.accent
                                : colors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPlaying ? colors.accent : colors.border,
                            ),
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 20,
                            color: isPlaying
                                ? colors.onAccent
                                : colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    station.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      CountryFlagImage(
                        countryCode: station.countryCode,
                        width: 14,
                        height: 10,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          station.countryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
    final String bgAsset = resolveStationThemeAsset(collection.title);
    return Semantics(
      button: true,
      label: '${collection.title}, $count stations',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: SizedBox(
            width: 224,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(bgAsset, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: colors.border),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                        child: Text(
                          '$count stations',
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        collection.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        collection.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
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
