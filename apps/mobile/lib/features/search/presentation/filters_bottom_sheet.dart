import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/explore_view_model.dart';

/// Backwards-compatible alias for Phase 1 tests.
typedef StationFilterState = StationFilterSelection;

/// Immutable filter draft shared by [SearchScreen] and [FiltersBottomSheet].
///
/// Follows the product rule: `workingOnly` is **ON by default**.
@immutable
class StationFilterSelection {
  const StationFilterSelection({
    this.workingOnly = true,
    this.httpsOnly = false,
    this.genreId,
    this.language,
    this.codec,
    this.minBitrateKbps,
    this.sort = StationSortOption.popular,
    this.query,
  });

  factory StationFilterSelection.fromDomain(
    StationFilter filter, {
    StationSortOption sort = StationSortOption.popular,
  }) {
    return StationFilterSelection(
      workingOnly: filter.workingNowOnly,
      httpsOnly: filter.httpsOnly,
      genreId: filter.genreId,
      language: filter.language,
      codec: filter.codec,
      minBitrateKbps: filter.minBitrateKbps,
      sort: sort,
      query: filter.query,
    );
  }

  final bool workingOnly;
  final bool httpsOnly;
  final String? genreId;
  final String? language;
  final String? codec;
  final int? minBitrateKbps;
  final StationSortOption sort;
  final String? query;

  int get activeFilterCount {
    int count = 0;
    if (!workingOnly) count++;
    if (httpsOnly) count++;
    if (genreId != null) count++;
    if (language != null) count++;
    if (codec != null) count++;
    if (minBitrateKbps != null) count++;
    if (sort != StationSortOption.popular) count++;
    return count;
  }

  StationFilter toStationFilter() {
    return StationFilter(
      workingNowOnly: workingOnly,
      httpsOnly: httpsOnly,
      genreId: genreId,
      language: language,
      codec: codec,
      minBitrateKbps: minBitrateKbps,
      query: query,
    );
  }

  StationFilterSelection copyWith({
    bool? workingOnly,
    bool? httpsOnly,
    String? Function()? genreId,
    String? Function()? language,
    String? Function()? codec,
    int? Function()? minBitrateKbps,
    StationSortOption? sort,
  }) {
    return StationFilterSelection(
      workingOnly: workingOnly ?? this.workingOnly,
      httpsOnly: httpsOnly ?? this.httpsOnly,
      genreId: genreId != null ? genreId() : this.genreId,
      language: language != null ? language() : this.language,
      codec: codec != null ? codec() : this.codec,
      minBitrateKbps: minBitrateKbps != null
          ? minBitrateKbps()
          : this.minBitrateKbps,
      sort: sort ?? this.sort,
      query: query,
    );
  }
}

/// Opens the station Filters bottom sheet and returns the updated
/// [StationFilterSelection] if applied, or `null` if dismissed.
Future<StationFilterSelection?> showStationFiltersSheet(
  BuildContext context, {
  required StationFilterSelection initial,
}) {
  return showModalBottomSheet<StationFilterSelection>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _FiltersBottomSheet(initial: initial),
  );
}

class _FiltersBottomSheet extends ConsumerStatefulWidget {
  const _FiltersBottomSheet({required this.initial});

  final StationFilterSelection initial;

  @override
  ConsumerState<_FiltersBottomSheet> createState() =>
      _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends ConsumerState<_FiltersBottomSheet> {
  late StationFilterSelection _draft;

  static const List<String> _codecs = <String>['MP3', 'AAC', 'AAC+', 'OGG'];
  static const List<int> _bitrates = <int>[64, 96, 128, 192];
  static const List<Genre> _fallbackGenres = <Genre>[
    Genre(id: 'afrobeats', name: 'Afrobeats'),
    Genre(id: 'pop', name: 'Pop'),
    Genre(id: 'news', name: 'News & Talk'),
    Genre(id: 'gospel', name: 'Gospel & Christian'),
    Genre(id: 'jazz', name: 'Jazz'),
    Genre(id: 'hiphop', name: 'Hip-Hop & R&B'),
    Genre(id: 'rock', name: 'Rock'),
    Genre(id: 'electronic', name: 'Electronic & Dance'),
  ];
  static const List<String> _fallbackLanguages = <String>[
    'English',
    'French',
    'German',
    'Portuguese',
    'Spanish',
    'Japanese',
    'Hindi',
    'Arabic',
  ];

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  String _sortLabel(StationSortOption option) {
    switch (option) {
      case StationSortOption.popular:
        return 'Most Popular';
      case StationSortOption.trending:
        return 'Trending';
      case StationSortOption.votes:
        return 'Most Voted';
      case StationSortOption.bitrate:
        return 'Highest Bitrate';
      case StationSortOption.nameAsc:
        return 'A–Z';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ExploreState? explore = ref
        .watch(exploreViewModelProvider)
        .asData
        ?.value;

    final List<Genre> genres = explore != null && explore.genres.isNotEmpty
        ? explore.genres.take(12).toList(growable: false)
        : _fallbackGenres;

    final List<String> languages =
        explore != null && explore.languages.isNotEmpty
        ? explore.languages
              .take(8)
              .map((Language l) => l.name)
              .toList(growable: false)
        : _fallbackLanguages;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters & Sort',
                      style: AppTypography.h3.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: AppSpacing.touchTarget,
                    child: TextButton(
                      onPressed: () => setState(
                        () => _draft = StationFilterSelection(
                          query: _draft.query,
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Working now only',
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Hide streams currently marked offline (ON by default)',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    value: _draft.workingOnly,
                    onChanged: (v) => setState(
                      () => _draft = _draft.copyWith(workingOnly: v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _FilterHeading('Sort by'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final StationSortOption option
                          in StationSortOption.values)
                        GenreChip(
                          label: _sortLabel(option),
                          selected: _draft.sort == option,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(sort: option),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterHeading('Genre'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final Genre genre in genres)
                        GenreChip(
                          label: genre.name,
                          selected: _draft.genreId == genre.id,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              genreId: () =>
                                  _draft.genreId == genre.id ? null : genre.id,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterHeading('Language'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final String lang in languages)
                        GenreChip(
                          label: lang,
                          selected: _draft.language == lang,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              language: () =>
                                  _draft.language == lang ? null : lang,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterHeading('Codec'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final String codec in _codecs)
                        GenreChip(
                          label: codec,
                          selected: _draft.codec == codec,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              codec: () => _draft.codec == codec ? null : codec,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _FilterHeading('Minimum bitrate'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final int kbps in _bitrates)
                        GenreChip(
                          label: '$kbps+ kbps',
                          selected: _draft.minBitrateKbps == kbps,
                          onTap: () => setState(
                            () => _draft = _draft.copyWith(
                              minBitrateKbps: () =>
                                  _draft.minBitrateKbps == kbps ? null : kbps,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: PrimaryButton(
                label: 'Apply Filters',
                icon: Icons.check_rounded,
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterHeading extends StatelessWidget {
  const _FilterHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.title.copyWith(color: colors.textPrimary),
      ),
    );
  }
}
