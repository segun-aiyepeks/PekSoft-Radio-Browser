import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/station/presentation/mock_station_tile.dart';
import 'package:peksoft_radio/mock/mock.dart';

class GenreDetailScreen extends StatefulWidget {
  const GenreDetailScreen({super.key, required this.genreName});

  final String genreName;

  @override
  State<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends State<GenreDetailScreen> {
  bool _workingOnly = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final MockGenre? genre = getMockGenres().cast<MockGenre?>().firstWhere(
      (g) => g?.name.toLowerCase() == widget.genreName.toLowerCase(),
      orElse: () => null,
    );
    final List<MockStation> stations = getMockStationsByGenre(
      widget.genreName,
      workingOnly: _workingOnly,
    );

    return Scaffold(
      appBar: AppBar(title: Text(genre?.name ?? widget.genreName)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
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
                          genre?.tagline ?? 'Curated radio stations',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${stations.length} stations in mock catalog',
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
              title: 'No ${widget.genreName} stations',
              message:
                  'Try toggling Working now off to include offline stations.',
              icon: Icons.music_off_rounded,
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
