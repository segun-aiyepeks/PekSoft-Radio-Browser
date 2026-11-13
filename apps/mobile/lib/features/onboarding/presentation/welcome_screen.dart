import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Onboarding Welcome screen: country pick, optional taste chips, visible Skip.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String _selectedCountryCode = 'NG';
  final Set<String> _selectedGenres = <String>{'Afrobeats', 'News'};

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<MockCountry> countries = getMockCountries().take(10).toList();
    final List<MockGenre> genres = getMockGenres().take(12).toList();

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
                onPressed: () => context.go('/home'),
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
              for (final MockCountry country in countries)
                GenreChip(
                  label: '${country.flagEmoji} ${country.name}',
                  selected: _selectedCountryCode == country.code,
                  onTap: () =>
                      setState(() => _selectedCountryCode = country.code),
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
              for (final MockGenre genre in genres)
                GenreChip(
                  label: genre.name,
                  selected: _selectedGenres.contains(genre.name),
                  onTap: () {
                    setState(() {
                      if (_selectedGenres.contains(genre.name)) {
                        _selectedGenres.remove(genre.name);
                      } else {
                        _selectedGenres.add(genre.name);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2xl),
          PrimaryButton(
            label: 'Start Listening',
            icon: Icons.headphones_rounded,
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip for now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
