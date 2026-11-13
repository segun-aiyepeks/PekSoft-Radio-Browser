import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/search/presentation/filters_bottom_sheet.dart';
import 'package:peksoft_radio/features/station/presentation/mock_station_tile.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Search screen covering empty, typing, results, and no-results states.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = '', this.initialLanguage});

  final String initialQuery;
  final String? initialLanguage;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  late StationFilterState _filters;

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
    _filters = StationFilterState(language: widget.initialLanguage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final StationFilterState? updated = await showStationFiltersSheet(
      context,
      initial: _filters,
    );
    if (updated != null && mounted) {
      setState(() => _filters = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final String query = _controller.text.trim();
    final bool hasActiveFilters =
        _filters.genre != null ||
        _filters.language != null ||
        _filters.codec != null ||
        _filters.minBitrateKbps != null ||
        !_filters.workingOnly;

    final bool isEmptyIdle = query.isEmpty && !hasActiveFilters;

    final List<MockStation> results = isEmptyIdle
        ? const <MockStation>[]
        : searchMockStations(
            query: query,
            workingOnly: _filters.workingOnly,
            genre: _filters.genre,
            language: _filters.language,
            codec: _filters.codec,
            minBitrateKbps: _filters.minBitrateKbps,
            sort: _filters.sort,
          );

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
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search stations, countries, genres...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              suffixIcon: query.isNotEmpty
                  ? SizedBox(
                      width: AppSpacing.touchTarget,
                      height: AppSpacing.touchTarget,
                      child: IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
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
            label: 'Open search filters',
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: IconButton(
                tooltip: 'Filters',
                onPressed: _openFilters,
                icon: Badge(
                  isLabelVisible: _filters.activeFilterCount > 0,
                  label: Text('${_filters.activeFilterCount}'),
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isEmptyIdle
          ? _EmptySearchView(
              suggestedTerms: _suggestedTerms,
              onSelectTerm: (term) {
                _controller.text = term;
                _controller.selection = TextSelection.collapsed(
                  offset: term.length,
                );
                setState(() {});
              },
            )
          : Column(
              children: [
                FilterChipBar(
                  items: [
                    FilterChipItem(
                      id: 'working',
                      label: _filters.workingOnly
                          ? 'Working now'
                          : 'All stations',
                      selected: _filters.workingOnly,
                    ),
                    if (_filters.genre != null)
                      FilterChipItem(
                        id: 'genre',
                        label: _filters.genre!,
                        selected: true,
                      ),
                    if (_filters.language != null)
                      FilterChipItem(
                        id: 'language',
                        label: _filters.language!,
                        selected: true,
                      ),
                    if (_filters.codec != null)
                      FilterChipItem(
                        id: 'codec',
                        label: _filters.codec!,
                        selected: true,
                      ),
                    if (_filters.minBitrateKbps != null)
                      FilterChipItem(
                        id: 'bitrate',
                        label: '${_filters.minBitrateKbps}+ kbps',
                        selected: true,
                      ),
                  ],
                  onToggle: (_) => _openFilters(),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (results.isEmpty)
                  Expanded(
                    child: EmptyState(
                      title: 'No stations found',
                      message:
                          'Try a different search term or adjust your active filters.',
                      icon: Icons.search_off_rounded,
                      actionLabel: _filters.workingOnly
                          ? 'Include offline stations'
                          : 'Reset filters',
                      onAction: () => setState(() {
                        if (_filters.workingOnly) {
                          _filters = _filters.copyWith(workingOnly: false);
                        } else {
                          _controller.clear();
                          _filters = const StationFilterState();
                        }
                      }),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      itemCount: results.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.xs,
                            ),
                            child: Text(
                              '${results.length} ${results.length == 1 ? 'station' : 'stations'} found',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textMuted,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          child: MockStationTile(station: results[index - 1]),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EmptySearchView extends StatelessWidget {
  const _EmptySearchView({
    required this.suggestedTerms,
    required this.onSelectTerm,
  });

  final List<String> suggestedTerms;
  final ValueChanged<String> onSelectTerm;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockGenre> popularGenres = getMockGenres().take(6).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Try searching for',
          style: AppTypography.title.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final String term in suggestedTerms)
              GenreChip(label: term, onTap: () => onSelectTerm(term)),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Browse popular genres',
          style: AppTypography.title.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final MockGenre g in popularGenres)
              GenreChip(
                label: g.name,
                onTap: () =>
                    context.push('/genre/${Uri.encodeComponent(g.name)}'),
              ),
          ],
        ),
      ],
    );
  }
}
