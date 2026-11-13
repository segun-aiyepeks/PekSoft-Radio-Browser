import 'package:flutter/material.dart';
import 'package:peksoft_radio/core/theme/app_theme.dart';
import 'package:peksoft_radio/core/theme/design_tokens.dart';
import 'package:peksoft_radio/core/widgets/genre_chip.dart';
import 'package:peksoft_radio/core/widgets/quality_badge.dart';
import 'package:peksoft_radio/core/widgets/station_logo.dart';

class StationTile extends StatelessWidget {
  const StationTile({
    super.key,
    required this.name,
    required this.countryLabel,
    this.genres = const [],
    this.codec = 'MP3',
    this.bitrateKbps = 128,
    this.isHls = false,
    this.isPlaying = false,
    this.isFavourite = false,
    this.isWorking = true,
    this.faviconUrl,
    this.onTap,
    this.onPlayTap,
    this.onFavouriteTap,
    this.onLongPress,
  });

  final String name;
  final String countryLabel;
  final List<String> genres;
  final String codec;
  final int bitrateKbps;
  final bool isHls;
  final bool isPlaying;
  final bool isFavourite;
  final bool isWorking;
  final String? faviconUrl;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onFavouriteTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visibleGenres = genres.take(2).toList();

    return Semantics(
      container: true,
      label:
          '$name, $countryLabel${isPlaying ? ', currently playing' : ''}${isWorking ? '' : ', unavailable'}',
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: isPlaying ? colors.accent : colors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StationLogo(
                  stationName: name,
                  faviconUrl: faviconUrl,
                  hasLogo: faviconUrl != null && faviconUrl!.isNotEmpty,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.title.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        isWorking
                            ? countryLabel
                            : '$countryLabel · Unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall.copyWith(
                          color: isWorking
                              ? colors.textSecondary
                              : colors.error,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final g in visibleGenres)
                            GenreChip(label: g, compact: true),
                          QualityBadge(
                            codec: codec,
                            bitrateKbps: bitrateKbps,
                            isHls: isHls,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Semantics(
                  button: true,
                  toggled: isFavourite,
                  label: isFavourite
                      ? 'Remove $name from favourites'
                      : 'Add $name to favourites',
                  child: SizedBox(
                    width: AppSpacing.touchTarget,
                    height: AppSpacing.touchTarget,
                    child: IconButton(
                      onPressed: onFavouriteTap,
                      icon: Icon(
                        isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavourite ? colors.accent : colors.textMuted,
                      ),
                      tooltip: isFavourite ? 'Unfavourite' : 'Favourite',
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  toggled: isPlaying,
                  label: isPlaying ? 'Pause $name' : 'Play $name',
                  child: SizedBox(
                    width: AppSpacing.touchTarget,
                    height: AppSpacing.touchTarget,
                    child: IconButton(
                      onPressed: onPlayTap,
                      style: IconButton.styleFrom(
                        backgroundColor: isPlaying
                            ? colors.accent
                            : colors.surfaceElevated,
                        foregroundColor: isPlaying
                            ? colors.onAccent
                            : colors.textPrimary,
                      ),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
