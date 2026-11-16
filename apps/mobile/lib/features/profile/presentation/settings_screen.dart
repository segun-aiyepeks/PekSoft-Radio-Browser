import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
import 'package:peksoft_radio/features/profile/presentation/view_models/settings_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<int?> _sleepOptions = <int?>[null, 15, 30, 45, 60];
  static const List<({String code, String label})> _languages =
      <({String code, String label})>[
        (code: 'en', label: 'English'),
        (code: 'fr', label: 'French'),
        (code: 'es', label: 'Spanish'),
        (code: 'pt', label: 'Portuguese'),
        (code: 'de', label: 'German'),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final AsyncValue<SettingsState> settingsAsync = ref.watch(
      settingsViewModelProvider,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        loading: () => const SkeletonList(itemCount: 4),
        error: (Object error, StackTrace _) => ErrorState(
          title: 'Could not load settings',
          message: error.toString(),
          onRetry: () => ref.read(settingsViewModelProvider.notifier).refresh(),
        ),
        data: (SettingsState state) {
          final UserSettings settings = state.settings;
          final SettingsViewModel notifier = ref.read(
            settingsViewModelProvider.notifier,
          );

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Data Saver'),
                      subtitle: const Text(
                        'Prefer lower-bitrate streams on cellular data',
                      ),
                      value: settings.dataSaver,
                      onChanged: notifier.toggleDataSaver,
                    ),
                    Divider(height: 1, color: colors.border),
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text(
                        'Curated collections & favourite station updates',
                      ),
                      value: settings.notifyCollections,
                      onChanged: notifier.toggleNotifyCollections,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Default sleep timer',
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final int? mins in _sleepOptions)
                    GenreChip(
                      label: mins == null ? 'Off' : '$mins min',
                      selected: settings.defaultSleepMinutes == mins,
                      onTap: () => notifier.setDefaultSleepMinutes(mins),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Theme',
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: appThemeController,
                builder: (context, mode, _) {
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      GenreChip(
                        label: 'Dark',
                        selected: mode == ThemeMode.dark,
                        onTap: () {
                          appThemeController.setMode(ThemeMode.dark);
                          notifier.setTheme(AppThemePreference.dark);
                        },
                      ),
                      GenreChip(
                        label: 'Light',
                        selected: mode == ThemeMode.light,
                        onTap: () {
                          appThemeController.setMode(ThemeMode.light);
                          notifier.setTheme(AppThemePreference.light);
                        },
                      ),
                      GenreChip(
                        label: 'System',
                        selected: mode == ThemeMode.system,
                        onTap: () {
                          appThemeController.setMode(ThemeMode.system);
                          notifier.setTheme(AppThemePreference.system);
                        },
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'App language',
                style: AppTypography.title.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final lang in _languages)
                    GenreChip(
                      label: lang.label,
                      selected: settings.languageCode == lang.code,
                      onTap: () => notifier.setLanguage(lang.code),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2xl),
              Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: ListTile(
                  minTileHeight: AppSpacing.touchTarget,
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: colors.error,
                  ),
                  title: Text(
                    'Delete Account',
                    style: AppTypography.title.copyWith(color: colors.error),
                  ),
                  subtitle: const Text('Permanently remove cloud data'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/delete-account'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
