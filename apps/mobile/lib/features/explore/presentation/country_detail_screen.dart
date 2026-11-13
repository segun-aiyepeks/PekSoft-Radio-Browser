import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/station/presentation/mock_station_tile.dart';
import 'package:peksoft_radio/mock/mock.dart';

class CountryDetailScreen extends StatefulWidget {
  const CountryDetailScreen({super.key, required this.countryCode});

  final String countryCode;

  @override
  State<CountryDetailScreen> createState() => _CountryDetailScreenState();
}

class _CountryDetailScreenState extends State<CountryDetailScreen> {
  bool _workingOnly = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final MockCountry? country = getMockCountries()
        .cast<MockCountry?>()
        .firstWhere(
          (c) => c?.code.toUpperCase() == widget.countryCode.toUpperCase(),
          orElse: () => null,
        );

    final String title = country != null
        ? '${country.flagEmoji} ${country.name}'
        : widget.countryCode.toUpperCase();
    final List<MockStation> stations = getMockStationsByCountry(
      widget.countryCode,
      workingOnly: _workingOnly,
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          if (country != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
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
                            '${country.workingCount} working · ${country.stationCount} total stations',
                            style: AppTypography.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            _workingOnly
                                ? 'Showing working stations only'
                                : 'Showing all stations',
                            style: AppTypography.caption.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      toggled: _workingOnly,
                      label: 'Working stations only',
                      child: Switch(
                        value: _workingOnly,
                        onChanged: (v) => setState(() => _workingOnly = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (stations.isEmpty)
            EmptyState(
              title: 'No stations in mock sample',
              message: _workingOnly
                  ? 'No working stations matched in this country sample.'
                  : 'This country has 0 stations in the Phase 1 mock sample.',
              icon: Icons.public_off_rounded,
              actionLabel: _workingOnly ? 'Show offline too' : null,
              onAction: _workingOnly
                  ? () => setState(() => _workingOnly = false)
                  : null,
            )
          else
            for (final MockStation station in stations)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: MockStationTile(station: station),
              ),
        ],
      ),
    );
  }
}
