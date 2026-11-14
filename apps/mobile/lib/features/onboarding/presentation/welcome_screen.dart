import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/utils/country_flag.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/explore_view_model.dart';
import 'package:peksoft_radio/features/onboarding/presentation/view_models/welcome_view_model.dart';

/// Onboarding Welcome screen: country pick, optional taste chips, visible Skip.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  static const List<Country> _fallbackCountries = <Country>[
    Country(code: 'NG', name: 'Nigeria'),
    Country(code: 'GH', name: 'Ghana'),
    Country(code: 'ZA', name: 'South Africa'),
    Country(code: 'GB', name: 'United Kingdom'),
    Country(code: 'US', name: 'United States'),
    Country(code: 'FR', name: 'France'),
    Country(code: 'DE', name: 'Germany'),
    Country(code: 'JP', name: 'Japan'),
    Country(code: 'BR', name: 'Brazil'),
    Country(code: 'IN', name: 'India'),
  ];

  static const List<Genre> _fallbackGenres = <Genre>[
    Genre(id: 'afrobeats', name: 'Afrobeats'),
    Genre(id: 'news', name: 'News & Talk'),
    Genre(id: 'pop', name: 'Pop'),
    Genre(id: 'gospel', name: 'Gospel & Christian'),
    Genre(id: 'jazz', name: 'Jazz'),
    Genre(id: 'hiphop', name: 'Hip-Hop & R&B'),
    Genre(id: 'rock', name: 'Rock'),
    Genre(id: 'electronic', name: 'Electronic & Dance'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final WelcomeState welcomeState = ref.watch(welcomeViewModelProvider);
    final WelcomeViewModel vm = ref.read(welcomeViewModelProvider.notifier);
    final AsyncValue<ExploreState> exploreAsync = ref.watch(
      exploreViewModelProvider,
    );

    final List<Country> countries =
        exploreAsync.asData?.value.countries.isNotEmpty == true
        ? exploreAsync.asData!.value.countries.take(10).toList(growable: false)
        : _fallbackCountries;

    final List<Genre> genres =
        exploreAsync.asData?.value.genres.isNotEmpty == true
        ? exploreAsync.asData!.value.genres.take(12).toList(growable: false)
        : _fallbackGenres;

    final String selectedCountry = welcomeState.selectedCountryCode ?? 'NG';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        actions: [
          Semantics(
            button: true,
            label: 'Skip onboarding and go to Home',
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: TextButton(
                onPressed: () {
                  vm.skip();
                  context.go('/home');
                },
                child: const Text('Skip'),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'Tune into your world',
            style: AppTypography.h2.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick a home country and a few genres you enjoy. Everything is optional — you can skip anytime.',
            style: AppTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Your country',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final Country country in countries)
                GenreChip(
                  label: '${countryFlagEmoji(country.code)} ${country.name}',
                  selected: selectedCountry == country.code,
                  onTap: () => vm.selectCountry(country.code),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'What do you like to hear? (Optional)',
            style: AppTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final Genre genre in genres)
                GenreChip(
                  label: genre.name,
                  selected: welcomeState.selectedGenreIds.contains(genre.id),
                  onTap: () => vm.toggleGenre(genre.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2xl),
          PrimaryButton(
            label: welcomeState.isSubmitting ? 'Saving...' : 'Start Listening',
            icon: Icons.headphones_rounded,
            onPressed: welcomeState.isSubmitting
                ? null
                : () async {
                    if (welcomeState.selectedCountryCode == null) {
                      vm.selectCountry(selectedCountry);
                    }
                    await vm.completeOnboarding();
                    if (context.mounted) {
                      context.go('/home');
                    }
                  },
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: TextButton(
                onPressed: () {
                  vm.skip();
                  context.go('/home');
                },
                child: const Text('Skip for now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
