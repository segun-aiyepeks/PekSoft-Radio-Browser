import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Countries'),
              Tab(text: 'Genres'),
              Tab(text: 'Languages'),
              Tab(text: 'Map'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CountriesTab(),
            _GenresTab(),
            _LanguagesTab(),
            _MapPlaceholderTab(),
          ],
        ),
      ),
    );
  }
}

class _CountriesTab extends StatelessWidget {
  const _CountriesTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockCountry> countries = getMockCountries();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: countries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final MockCountry country = countries[index];
        return Semantics(
          button: true,
          label: '${country.name}, ${country.workingCount} working stations',
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
                    Text(country.flagEmoji, style: AppTypography.h2),
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
                            '${country.workingCount} working · ${country.stationCount} total',
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
  const _GenresTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockGenre> genres = getMockGenres();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: genres.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final MockGenre genre = genres[index];
        return Semantics(
          button: true,
          label: '${genre.name}, ${genre.stationCount} stations',
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: () =>
                  context.push('/genre/${Uri.encodeComponent(genre.name)}'),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            genre.name,
                            style: AppTypography.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${genre.tagline} · ${genre.stationCount} stations',
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

class _LanguagesTab extends StatelessWidget {
  const _LanguagesTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockLanguage> languages = getMockLanguages();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: languages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final MockLanguage lang = languages[index];
        return Semantics(
          button: true,
          label: '${lang.name} stations, ${lang.stationCount} total',
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: InkWell(
              onTap: () => context.push(
                '/search?language=${Uri.encodeComponent(lang.name)}',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.name,
                            style: AppTypography.title.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '${lang.stationCount} stations',
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

class _MapPlaceholderTab extends StatelessWidget {
  const _MapPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockCountry> featured = getMockCountries().take(6).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Semantics(
          label: 'Interactive radio map placeholder',
          child: Container(
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
                  style: AppTypography.h2.copyWith(color: colors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Pin-drop city tuning lands after Phase 1. Jump directly to a featured radio hub below:',
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
                    for (final MockCountry c in featured)
                      GenreChip(
                        label: '${c.flagEmoji} ${c.name}',
                        onTap: () => context.push('/country/${c.code}'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
