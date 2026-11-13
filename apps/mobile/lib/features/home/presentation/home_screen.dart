import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/search/presentation/filters_bottom_sheet.dart';
import 'package:peksoft_radio/features/station/presentation/mock_station_tile.dart';
import 'package:peksoft_radio/mock/mock.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _quickGenres = <String>[
    'All',
    'Afrobeats',
    'News',
    'Jazz',
    'Pop',
    'Lo-Fi',
    'Electronic',
  ];

  int _selectedGenreIndex = 0;
  StationFilterState _filters = const StationFilterState();

  Future<void> _openFilters() async {
    final StationFilterState? next = await showStationFiltersSheet(
      context,
      initial: _filters,
    );
    if (next != null && mounted) {
      setState(() => _filters = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final String? chipGenre = _selectedGenreIndex == 0
        ? _filters.genre
        : _quickGenres[_selectedGenreIndex];

    final List<MockStation> popularStations = searchMockStations(
      workingOnly: _filters.workingOnly,
      genre: chipGenre,
      language: _filters.language,
      codec: _filters.codec,
      minBitrateKbps: _filters.minBitrateKbps,
      sort: _filters.sort,
    );

    final List<MockCuratedCollection> collections = getMockCuratedCollections();

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
                  isLabelVisible: _filters.activeFilterCount > 0,
                  label: Text('${_filters.activeFilterCount}'),
                  child: const Icon(Icons.tune_rounded),
                ),
                onPressed: _openFilters,
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
      body: ListView(
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
                          'Search 40+ mock stations worldwide...',
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
              for (int i = 0; i < _quickGenres.length; i++)
                FilterChipItem(
                  id: '$i',
                  label: _quickGenres[i],
                  selected: i == _selectedGenreIndex,
                ),
            ],
            onToggle: (id) =>
                setState(() => _selectedGenreIndex = int.parse(id)),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: collections.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final MockCuratedCollection col = collections[index];
                final List<MockStation> colStations =
                    getMockStationsForCollection(col);
                return _CollectionCard(
                  collection: col,
                  stationCount: colStations.length,
                  onTap: () {
                    if (colStations.isNotEmpty) {
                      context.push('/station/${colStations.first.id}');
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AdSlotPlaceholder(),
          const SizedBox(height: AppSpacing.sm),
          SectionHeader(
            title: _filters.workingOnly
                ? 'Live & working now'
                : 'All mock stations',
            actionLabel: '${popularStations.length} stations',
            onActionTap: _openFilters,
          ),
          if (popularStations.isEmpty)
            EmptyState(
              title: 'No matching stations',
              message: 'Try clearing a filter or choosing another genre.',
              icon: Icons.radio_rounded,
              actionLabel: 'Reset filters',
              onAction: () => setState(() {
                _selectedGenreIndex = 0;
                _filters = const StationFilterState();
              }),
            )
          else
            for (final MockStation station in popularStations.take(10))
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: MockStationTile(station: station),
              ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.collection,
    required this.stationCount,
    required this.onTap,
  });

  final MockCuratedCollection collection;
  final int stationCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      label: '${collection.title}, $stationCount stations',
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
                  '$stationCount stations · Mock',
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
