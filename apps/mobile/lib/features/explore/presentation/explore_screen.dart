import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/utils/country_flag.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/explore_view_model.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ExploreState> exploreAsync = ref.watch(
      exploreViewModelProvider,
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explore'),
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
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (index) =>
                ref.read(exploreViewModelProvider.notifier).selectTab(index),
            tabs: const [
              Tab(text: 'Countries'),
              Tab(text: 'Genres'),
              Tab(text: 'Languages'),
              Tab(text: 'Map'),
            ],
          ),
        ),
        body: exploreAsync.when(
          loading: () => const SkeletonList(itemCount: 6),
          error: (Object error, StackTrace _) => ErrorState(
            title: 'Could not load catalog',
            message: error.toString(),
            onRetry: () =>
                ref.read(exploreViewModelProvider.notifier).refresh(),
          ),
          data: (ExploreState explore) {
            if (explore.error != null &&
                explore.countries.isEmpty &&
                explore.genres.isEmpty) {
              return ErrorState(
                title: 'Could not load catalog',
                message: explore.error!.message,
                onRetry: () =>
                    ref.read(exploreViewModelProvider.notifier).refresh(),
              );
            }
            return TabBarView(
              children: [
                _CountriesTab(countries: explore.countries),
                _GenresTab(genres: explore.genres),
                _LanguagesTab(languages: explore.languages),
                const _MapPlaceholderTab(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountriesTab extends StatelessWidget {
  const _CountriesTab({required this.countries});

  final List<Country> countries;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (countries.isEmpty) {
      return const EmptyState(
        title: 'No countries loaded',
        message: 'Pull to refresh or check your connection.',
        icon: Icons.public_off_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: countries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final Country country = countries[index];
        final String flag = countryFlagEmoji(country.code);
        return Semantics(
          button: true,
          label: '${country.name}, ${country.stationCount} stations',
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: () => context.push('/country/${country.code}'),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.touchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Text(flag, style: AppTypography.h2),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            country.name,
                            style: AppTypography.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${country.stationCount} stations',
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GenresTab extends StatelessWidget {
  const _GenresTab({required this.genres});

  final List<Genre> genres;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (genres.isEmpty) {
      return const EmptyState(
        title: 'No genres loaded',
        message: 'Canonical genres will appear here.',
        icon: Icons.music_off_rounded,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.45,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        final Genre genre = genres[index];
        return Semantics(
          button: true,
          label: '${genre.name}, ${genre.stationCount} stations',
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: InkWell(
              onTap: () =>
                  context.push('/genre/${Uri.encodeComponent(genre.id)}'),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genre.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(color: colors.accent),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        genre.tagline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${genre.stationCount} stations',
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
      },
    );
  }
}

class _LanguagesTab extends StatelessWidget {
  const _LanguagesTab({required this.languages});

  final List<Language> languages;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (languages.isEmpty) {
      return const EmptyState(
        title: 'No languages loaded',
        message: 'Pull to refresh or check your connection.',
        icon: Icons.translate_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: languages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final Language language = languages[index];
        return Semantics(
          button: true,
          label: '${language.name}, ${language.stationCount} stations',
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: () => context.push(
                '/search?language=${Uri.encodeComponent(language.name)}',
              ),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.touchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.translate_rounded, color: colors.accent),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        language.name,
                        style: AppTypography.title.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${language.stationCount}',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.chevron_right_rounded, color: colors.textMuted),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapPlaceholderTab extends StatelessWidget {
  const _MapPlaceholderTab();

  static const List<({String code, String label})> _hubs = [
    (code: 'NG', label: '🇳🇬 Lagos'),
    (code: 'GH', label: '🇬🇭 Accra'),
    (code: 'GB', label: '🇬🇧 London'),
    (code: 'US', label: '🇺🇸 New York'),
    (code: 'JP', label: '🇯🇵 Tokyo'),
    (code: 'BR', label: '🇧🇷 São Paulo'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Icon(
                Icons.public_rounded,
                size: AppSpacing.s3xl,
                color: colors.accent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'World Radio Map (Placeholder)',
                style: AppTypography.h3.copyWith(color: colors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Visual map pins using Radio Browser geo_lat / geo_long coordinates.',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  for (final hub in _hubs)
                    GenreChip(
                      label: hub.label,
                      onTap: () => context.push('/country/${hub.code}'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
