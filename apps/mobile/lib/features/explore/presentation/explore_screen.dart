import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/catalog/domain/language.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/explore_view_model.dart';
import 'package:peksoft_radio/features/explore/presentation/world_radio_map_tab.dart';

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
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _CountriesTab(countries: explore.countries),
                _GenresTab(genres: explore.genres),
                _LanguagesTab(languages: explore.languages),
                const WorldRadioMapTab(),
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
                    CountryFlagImage(
                      countryCode: country.code,
                      width: 36,
                      height: 26,
                      borderRadius: 6,
                    ),
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
        final String genreAsset = resolveStationThemeAsset(
          genre.name,
          genres: [genre.id],
        );
        return Semantics(
          button: true,
          label: '${genre.name}, ${genre.stationCount} stations',
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () =>
                  context.push('/genre/${Uri.encodeComponent(genre.id)}'),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(genreAsset, fit: BoxFit.cover),
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
                        Text(
                          genre.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.title.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${genre.stationCount} stations',
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
