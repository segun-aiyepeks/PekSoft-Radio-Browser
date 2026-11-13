import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Opens the Report Station bottom sheet (UI-only in Phase 1).
Future<void> showReportStationSheet(BuildContext context, MockStation station) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ReportStationSheet(station: station),
  );
}

class _ReportStationSheet extends StatefulWidget {
  const _ReportStationSheet({required this.station});

  final MockStation station;

  @override
  State<_ReportStationSheet> createState() => _ReportStationSheetState();
}

class _ReportStationSheetState extends State<_ReportStationSheet> {
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
                'Let us know what is wrong with this stream (mock UI only).',
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
              PrimaryButton(
                label: 'Submit Report',
                icon: Icons.flag_outlined,
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Report recorded (mock): $_selectedReason'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
