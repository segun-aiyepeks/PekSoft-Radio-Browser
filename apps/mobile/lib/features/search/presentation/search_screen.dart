import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/search/presentation/filters_bottom_sheet.dart';
import 'package:peksoft_radio/features/search/presentation/view_models/search_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';
import 'package:peksoft_radio/features/station/presentation/station_list_tile.dart';

/// Search screen covering empty, typing, loading, results, no-results, and
/// error states wired to [SearchViewModel].
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery = '', this.initialLanguage});

  final String initialQuery;
  final String? initialLanguage;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  static const List<String> _suggestedTerms = <String>[
    'Wazobia',
    'BBC',
    'Jazz',
    'Lo-Fi',
    'Tokyo',
    'Bollywood',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final SearchViewModel vm = ref.read(searchViewModelProvider.notifier);
      if (widget.initialQuery.isNotEmpty) {
        vm.setQuery(widget.initialQuery);
      }
      if (widget.initialLanguage != null) {
        vm.applyFilter(
          StationFilter(
            query: widget.initialQuery,
            language: widget.initialLanguage,
          ),
        );
      } else if (widget.initialQuery.isNotEmpty) {
        vm.submitSearch();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final SearchState current = ref.read(searchViewModelProvider);
    final StationFilterSelection? updated = await showStationFiltersSheet(
      context,
      initial: StationFilterSelection.fromDomain(
        current.filter,
        sort: current.sort,
      ),
    );
    if (updated != null && mounted) {
      final SearchViewModel vm = ref.read(searchViewModelProvider.notifier);
      await vm.applyFilter(updated.toStationFilter());
      await vm.setSort(updated.sort);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final SearchState state = ref.watch(searchViewModelProvider);
    final SearchViewModel vm = ref.read(searchViewModelProvider.notifier);

    final StationFilterSelection selection = StationFilterSelection.fromDomain(
      state.filter,
      sort: state.sort,
    );

    final bool hasActiveFilters = selection.activeFilterCount > 0;
    final bool isIdle = !state.hasSearched && state.query.trim().isEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Semantics(
          textField: true,
          label: 'Search radio stations, countries, genres, or languages',
          child: TextField(
            controller: _controller,
            autofocus: widget.initialQuery.isEmpty && !hasActiveFilters,
            textInputAction: TextInputAction.search,
            onChanged: vm.setQuery,
            onSubmitted: (_) => vm.submitSearch(),
            decoration: InputDecoration(
              hintText: 'Search stations, countries, genres...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              suffixIcon: state.query.isNotEmpty
                  ? SizedBox(
                      width: AppSpacing.touchTarget,
                      height: AppSpacing.touchTarget,
                      child: IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          vm.clearQuery();
                        },
                      ),
                    )
                  : null,
            ),
          ),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Filter search results',
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: IconButton(
                tooltip: 'Filters',
                icon: Badge(
                  isLabelVisible: selection.activeFilterCount > 0,
                  label: Text('${selection.activeFilterCount}'),
                  child: const Icon(Icons.tune_rounded),
                ),
                onPressed: _openFilters,
              ),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const SkeletonList(itemCount: 6);
          }
          if (state.error != null) {
            return ErrorState(
              title: 'Search failed',
              message: state.error!.message,
              onRetry: vm.submitSearch,
            );
          }
          if (isIdle) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Try searching for',
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final String term in _suggestedTerms)
                      GenreChip(
                        label: term,
                        onTap: () {
                          _controller.text = term;
                          vm.setQuery(term);
                          vm.submitSearch();
                        },
                      ),
                  ],
                ),
                if (state.recentQueries.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Recent searches',
                    style: AppTypography.title.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final String term in state.recentQueries)
                        GenreChip(
                          label: term,
                          onTap: () {
                            _controller.text = term;
                            vm.setQuery(term);
                            vm.submitSearch();
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                const EmptyState(
                  title: 'Find live radio worldwide',
                  message:
                      'Search by station name, country, genre, or open Filters to refine codecs and bitrate.',
                  icon: Icons.search_rounded,
                ),
              ],
            );
          }
          if (state.hasSearched && state.results.isEmpty) {
            return EmptyState(
              title: 'No stations found',
              message:
                  'No stations matched your search. Try another term or reset filters.',
              icon: Icons.search_off_rounded,
              actionLabel: 'Reset search & filters',
              onAction: () {
                _controller.clear();
                vm.clearQuery();
                vm.resetFilters();
              },
            );
          }
          if (!state.hasSearched) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                PrimaryButton(
                  label: 'Search "${state.query.trim()}"',
                  icon: Icons.search_rounded,
                  onPressed: vm.submitSearch,
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.results.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Text(
                  '${state.results.length} results',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                );
              }
              final Station station = state.results[index - 1];
              return StationListTile(station: station);
            },
          );
        },
      ),
    );
  }
}
