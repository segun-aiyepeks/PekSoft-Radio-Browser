import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/theme/theme_controller.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<int?> _sleepOptions = <int?>[null, 15, 30, 45, 60];
  static const List<String> _languages = <String>[
    'English',
    'French',
    'Spanish',
    'Portuguese',
    'German',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: mockSessionController,
        builder: (context, _) {
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
                      value: mockSessionController.dataSaver,
                      onChanged: mockSessionController.setDataSaver,
                    ),
                    Divider(height: 1, color: colors.border),
                    SwitchListTile(
                      title: const Text('Notifications'),
                      subtitle: const Text(
                        'Curated collections & favourite station updates',
                      ),
                      value: mockSessionController.notifyCollections,
                      onChanged: mockSessionController.setNotifyCollections,
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
                      selected:
                          mockSessionController.defaultSleepMinutes == mins,
                      onTap: () =>
                          mockSessionController.setDefaultSleepMinutes(mins),
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
                        onTap: () => appThemeController.setMode(ThemeMode.dark),
                      ),
                      GenreChip(
                        label: 'Light',
                        selected: mode == ThemeMode.light,
                        onTap: () =>
                            appThemeController.setMode(ThemeMode.light),
                      ),
                      GenreChip(
                        label: 'System',
                        selected: mode == ThemeMode.system,
                        onTap: () =>
                            appThemeController.setMode(ThemeMode.system),
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
                  for (final String lang in _languages)
                    GenreChip(
                      label: lang,
                      selected: mockSessionController.appLanguage == lang,
                      onTap: () => mockSessionController.setAppLanguage(lang),
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
