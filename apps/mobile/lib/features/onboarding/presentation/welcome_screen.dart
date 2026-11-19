import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/country.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/explore/presentation/view_models/explore_view_model.dart';
import 'package:peksoft_radio/features/onboarding/presentation/view_models/welcome_view_model.dart';

/// 3-page Onboarding flow:
///   1) Discover global radio in one tap
///   2) Pick your home country (with real flag images)
///   3) Pick your favourite genres & Start Listening
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    Genre(id: 'sports', name: 'Sports'),
    Genre(id: 'hiphop', name: 'Hip-Hop & R&B'),
    Genre(id: 'rock', name: 'Rock'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        ? exploreAsync.asData!.value.genres.take(8).toList(growable: false)
        : _fallbackGenres;

    final String selectedCountry = welcomeState.selectedCountryCode ?? 'NG';

    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${_currentPage + 1} of 3'),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int idx) {
                  setState(() => _currentPage = idx);
                },
                children: [
                  // Page 1: Global radio discovery
                  _OnboardingIntroPage(),
                  // Page 2: Home country picker
                  _OnboardingCountryPage(
                    countries: countries,
                    selectedCountry: selectedCountry,
                    onSelect: vm.selectCountry,
                  ),
                  // Page 3: Genre taste picker
                  _OnboardingGenrePage(
                    genres: genres,
                    selectedGenreIds: welcomeState.selectedGenreIds.toSet(),
                    onToggleGenre: vm.toggleGenre,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(3, (int idx) {
                      final bool active = idx == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? colors.accent : colors.border,
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_currentPage < 2)
                    PrimaryButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _nextPage,
                    )
                  else
                    PrimaryButton(
                      label: 'Start Listening',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () async {
                        await vm.completeOnboarding();
                        if (context.mounted) {
                          context.go('/home');
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingIntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - AppSpacing.xl * 2).clamp(
              0,
              double.infinity,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.xl),
                child: Image.asset(
                  'assets/images/genres/afrobeats.jpg',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Every radio station in the world',
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Stream 40,000+ live FM and internet stations from 195+ countries with zero setup.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingCountryPage extends StatelessWidget {
  const _OnboardingCountryPage({
    required this.countries,
    required this.selectedCountry,
    required this.onSelect,
  });

  final List<Country> countries;
  final String selectedCountry;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Tune into your world',
          style: AppTypography.h2.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pick your home country so we surface verified local stations first.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final Country country in countries)
              ChoiceChip(
                avatar: CountryFlagImage(
                  countryCode: country.code,
                  width: 22,
                  height: 16,
                  borderRadius: 3,
                ),
                label: Text(country.name),
                selected: selectedCountry == country.code,
                onSelected: (_) => onSelect(country.code),
              ),
          ],
        ),
      ],
    );
  }
}

class _OnboardingGenrePage extends StatelessWidget {
  const _OnboardingGenrePage({
    required this.genres,
    required this.selectedGenreIds,
    required this.onToggleGenre,
  });

  final List<Genre> genres;
  final Set<String> selectedGenreIds;
  final ValueChanged<String> onToggleGenre;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'What do you love to hear?',
          style: AppTypography.h2.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pick a few genres to personalise your Home feed. You can change this anytime.',
          style: AppTypography.body.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisExtent:
                96 * MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.8),
          ),
          itemCount: genres.length,
          itemBuilder: (BuildContext context, int index) {
            final Genre genre = genres[index];
            final bool selected = selectedGenreIds.contains(genre.id);
            final String asset = resolveStationThemeAsset(
              genre.name,
              genres: [genre.id],
            );
            return Semantics(
              button: true,
              selected: selected,
              label: genre.name,
              excludeSemantics: true,
              child: InkWell(
                onTap: () => onToggleGenre(genre.id),
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: selected ? colors.accent : colors.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        asset,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                      if (selected)
                        Positioned(
                          top: AppSpacing.xs,
                          right: AppSpacing.xs,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: colors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: colors.onAccent,
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            genre.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
