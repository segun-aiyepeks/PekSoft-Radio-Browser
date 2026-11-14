import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';

/// Opens the Sleep Timer bottom sheet for timer selection.
Future<void> showSleepTimerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (context) => const _SleepTimerSheet(),
  );
}

class _SleepTimerSheet extends ConsumerWidget {
  const _SleepTimerSheet();

  static const List<({int? minutes, String label})> _presets =
      <({int? minutes, String label})>[
        (minutes: null, label: 'Off'),
        (minutes: 15, label: '15 minutes'),
        (minutes: 30, label: '30 minutes'),
        (minutes: 45, label: '45 minutes'),
        (minutes: 60, label: '60 minutes'),
        (minutes: 90, label: '90 minutes'),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final Duration? remaining = ref
        .watch(playbackViewModelProvider)
        .playback
        .sleepTimerRemaining;
    final int? active = remaining?.inMinutes;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(Icons.bedtime_rounded, color: colors.accent),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sleep Timer',
                      style: AppTypography.h2.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.border),
              for (final preset in _presets)
                Semantics(
                  button: true,
                  selected: active == preset.minutes,
                  label: 'Set sleep timer to ${preset.label}',
                  child: ListTile(
                    minTileHeight: AppSpacing.touchTarget,
                    title: Text(
                      preset.label,
                      style: AppTypography.body.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    trailing: active == preset.minutes
                        ? Icon(Icons.check_rounded, color: colors.accent)
                        : null,
                    onTap: () {
                      final notifier = ref.read(
                        playbackViewModelProvider.notifier,
                      );
                      if (preset.minutes == null) {
                        notifier.cancelSleepTimer();
                      } else {
                        notifier.setSleepTimer(
                          Duration(minutes: preset.minutes!),
                        );
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
