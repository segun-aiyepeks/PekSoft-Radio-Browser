import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';

class ComponentGalleryScreen extends StatefulWidget {
  const ComponentGalleryScreen({super.key});

  @override
  State<ComponentGalleryScreen> createState() => _ComponentGalleryScreenState();
}

class _ComponentGalleryScreenState extends State<ComponentGalleryScreen> {
  final Set<String> _selectedFilters = {'working_now', 'afrobeats'};
  bool _isPlaying = false;
  bool _isFavourite = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Component Gallery (Dev)'),
        actions: [
          Semantics(
            button: true,
            label: isDark ? 'Switch to light theme' : 'Switch to dark theme',
            child: SizedBox(
              width: AppSpacing.touchTarget,
              height: AppSpacing.touchTarget,
              child: IconButton(
                onPressed: appThemeController.toggle,
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
                tooltip: isDark ? 'Light theme' : 'Dark theme',
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.s3xl),
        children: [
          const SectionHeader(title: '1. StationLogo & QualityBadge'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: const [
                StationLogo(stationName: 'Wazobia FM: Lagos', hasLogo: true),
                StationLogo(stationName: 'BBC World Service'),
                StationLogo(stationName: 'Cool FM 96.9'),
                QualityBadge(codec: 'MP3', bitrateKbps: 128),
                QualityBadge(codec: 'AAC+', bitrateKbps: 64, isHls: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '2. GenreChip & FilterChipBar'),
          FilterChipBar(
            items: [
              FilterChipItem(
                id: 'working_now',
                label: 'Working now',
                selected: _selectedFilters.contains('working_now'),
              ),
              FilterChipItem(
                id: 'afrobeats',
                label: 'Afrobeats',
                selected: _selectedFilters.contains('afrobeats'),
              ),
              FilterChipItem(
                id: 'news',
                label: 'News & Talk',
                selected: _selectedFilters.contains('news'),
              ),
              FilterChipItem(
                id: 'jazz',
                label: 'Jazz',
                selected: _selectedFilters.contains('jazz'),
              ),
            ],
            onToggle: (id) {
              setState(() {
                if (_selectedFilters.contains(id)) {
                  _selectedFilters.remove(id);
                } else {
                  _selectedFilters.add(id);
                }
              });
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: '3. StationTile',
            actionLabel: 'See all',
            onActionTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                StationTile(
                  name: 'Wazobia FM: Lagos',
                  countryLabel: 'Nigeria',
                  genres: const ['Afrobeats', 'Talk'],
                  codec: 'MP3',
                  bitrateKbps: 128,
                  isPlaying: _isPlaying,
                  isFavourite: _isFavourite,
                  onPlayTap: () => setState(() => _isPlaying = !_isPlaying),
                  onFavouriteTap: () =>
                      setState(() => _isFavourite = !_isFavourite),
                ),
                const SizedBox(height: AppSpacing.sm),
                const StationTile(
                  name: 'BBC Radio 1Xtra',
                  countryLabel: 'United Kingdom',
                  genres: ['Hip-Hop', 'R&B'],
                  codec: 'AAC',
                  bitrateKbps: 96,
                  isHls: true,
                  isWorking: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '4. PrimaryButton & AdSlotPlaceholder'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Start Listening',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                const PrimaryButton(label: 'Loading...', isLoading: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AdSlotPlaceholder(
            variant: AdSlotVariant.nativeCard,
            onRemoveAdsTap: () {},
          ),
          const AdSlotPlaceholder(variant: AdSlotVariant.banner),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '5. EmptyState & ErrorState'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.border),
            ),
            child: const EmptyState(
              title: 'No stations found',
              message: 'Try clearing filters or turning off Working now.',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: colors.border),
            ),
            child: ErrorState(
              title: 'Could not reach mirrors',
              message: 'Check your connection and retry.',
              onRetry: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader(title: '6. SkeletonList'),
          const SkeletonList(itemCount: 3, shrinkWrap: true),
        ],
      ),
    );
  }
}
