import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Opens the Report Station bottom sheet.
Future<void> showReportStationSheet(BuildContext context, Station station) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ReportStationSheet(station: station),
  );
}

class _ReportStationSheet extends ConsumerStatefulWidget {
  const _ReportStationSheet({required this.station});

  final Station station;

  @override
  ConsumerState<_ReportStationSheet> createState() =>
      _ReportStationSheetState();
}

class _ReportStationSheetState extends ConsumerState<_ReportStationSheet> {
  static const List<String> _reasons = <String>[
    'Stream won\'t play / dead link',
    'Wrong country or genre',
    'Poor audio quality',
    'Duplicate station',
    'Other issue',
  ];

  String _selectedReason = _reasons.first;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadii.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report ${widget.station.name}',
                style: AppTypography.h2.copyWith(color: colors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Let us know what is wrong with this stream.',
                style: AppTypography.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final String reason in _reasons)
                    GenreChip(
                      label: reason,
                      selected: _selectedReason == reason,
                      onTap: () => setState(() => _selectedReason = reason),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                textField: true,
                label: 'Optional details about the station issue',
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional notes (optional)',
                    hintText: 'E.g. silent audio, wrong metadata...',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.touchTarget,
                child: FilledButton(
                  onPressed: () {
                    final String details = _notesController.text.trim();
                    final String reason = details.isEmpty
                        ? _selectedReason
                        : '$_selectedReason: $details';
                    ref
                        .read(playbackViewModelProvider.notifier)
                        .reportCurrentStation(reason);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Report recorded: $_selectedReason'),
                      ),
                    );
                  },
                  child: const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
