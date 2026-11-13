import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Immutable filter state shared by Search and FiltersBottomSheet.
///
/// Follows the product rule: `workingOnly` is **ON by default**.
@immutable
class StationFilterState {
  const StationFilterState({
    this.workingOnly = true,
    this.genre,
    this.language,
    this.codec,
    this.minBitrateKbps,
    this.sort = MockStationSort.popular,
  });

  final bool workingOnly;
  final String? genre;
  final String? language;
  final String? codec;
  final int? minBitrateKbps;
  final MockStationSort sort;

  int get activeFilterCount {
    int count = 0;
    if (!workingOnly) count++;
    if (genre != null) count++;
    if (language != null) count++;
    if (codec != null) count++;
    if (minBitrateKbps != null) count++;
    if (sort != MockStationSort.popular) count++;
    return count;
  }

  StationFilterState copyWith({
    bool? workingOnly,
    String? Function()? genre,
    String? Function()? language,
    String? Function()? codec,
    int? Function()? minBitrateKbps,
    MockStationSort? sort,
  }) {
    return StationFilterState(
      workingOnly: workingOnly ?? this.workingOnly,
      genre: genre != null ? genre() : this.genre,
      language: language != null ? language() : this.language,
      codec: codec != null ? codec() : this.codec,
      minBitrateKbps: minBitrateKbps != null
          ? minBitrateKbps()
          : this.minBitrateKbps,
      sort: sort ?? this.sort,
    );
  }
}

/// Opens the station Filters bottom sheet and returns the updated
/// [StationFilterState] if applied, or `null` if dismissed.
Future<StationFilterState?> showStationFiltersSheet(
  BuildContext context, {
  required StationFilterState initial,
}) {
  return showModalBottomSheet<StationFilterState>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _FiltersBottomSheet(initial: initial),
  );
}

class _FiltersBottomSheet extends StatefulWidget {
  const _FiltersBottomSheet({required this.initial});

  final StationFilterState initial;

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  late StationFilterState _draft;

  static const List<String> _codecs = <String>['MP3', 'AAC', 'AAC+', 'OGG'];
  static const List<int> _bitrates = <int>[64, 96, 128, 192];

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockGenre> genres = getMockGenres().take(10).toList();
    final List<MockLanguage> languages = getMockLanguages();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filters & Sort',
                        style: AppTypography.h2.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Reset filters to defaults',
                      child: SizedBox(
                        height: AppSpacing.touchTarget,
                        child: TextButton(
                          onPressed: () => setState(
                            () => _draft = const StationFilterState(),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    Semantics(
                      toggled: _draft.workingOnly,
                      label: 'Working stations only',
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Working now only',
                          style: AppTypography.title.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Hide offline or broken streams (ON by default)',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        value: _draft.workingOnly,
                        onChanged: (value) => setState(
                          () => _draft = _draft.copyWith(workingOnly: value),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Sort by',
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final MockStationSort s in MockStationSort.values)
                          GenreChip(
                            label: _sortLabel(s),
                            selected: _draft.sort == s,
                            onTap: () => setState(
                              () => _draft = _draft.copyWith(sort: s),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Genre',
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final MockGenre g in genres)
                          GenreChip(
                            label: g.name,
                            selected: _draft.genre == g.name,
                            onTap: () => setState(() {
                              final next = _draft.genre == g.name
                                  ? null
                                  : g.name;
                              _draft = _draft.copyWith(genre: () => next);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Language',
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final MockLanguage lang in languages)
                          GenreChip(
                            label: lang.name,
                            selected: _draft.language == lang.name,
                            onTap: () => setState(() {
                              final next = _draft.language == lang.name
                                  ? null
                                  : lang.name;
                              _draft = _draft.copyWith(language: () => next);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Codec',
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final String codec in _codecs)
                          GenreChip(
                            label: codec,
                            selected: _draft.codec == codec,
                            onTap: () => setState(() {
                              final next = _draft.codec == codec ? null : codec;
                              _draft = _draft.copyWith(codec: () => next);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Minimum bitrate',
                      style: AppTypography.title.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final int kbps in _bitrates)
                          GenreChip(
                            label: '$kbps+ kbps',
                            selected: _draft.minBitrateKbps == kbps,
                            onTap: () => setState(() {
                              final next = _draft.minBitrateKbps == kbps
                                  ? null
                                  : kbps;
                              _draft = _draft.copyWith(
                                minBitrateKbps: () => next,
                              );
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: PrimaryButton(
                  label: 'Apply Filters',
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(context).pop(_draft),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _sortLabel(MockStationSort sort) {
    return switch (sort) {
      MockStationSort.popular => 'Most Popular',
      MockStationSort.votes => 'Top Voted',
      MockStationSort.name => 'A–Z',
      MockStationSort.bitrate => 'Highest Bitrate',
    };
  }
}
