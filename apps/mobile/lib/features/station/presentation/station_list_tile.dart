import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/utils/country_flag.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/features/catalog/domain/genre.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/presentation/view_models/player_view_model.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Riverpod-wired [StationTile] backed by [PlayerViewModel] and
/// [LibraryViewModel] for domain [Station] models.
class StationListTile extends ConsumerWidget {
  const StationListTile({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlayerState playerState = ref.watch(playerViewModelProvider);
    final bool isCurrent =
        playerState.playback.currentStation?.id == station.id;
    final bool isPlaying =
        isCurrent && playerState.playback.status == PlaybackStatus.playing;

    final AsyncValue<LibraryState> libraryAsync = ref.watch(
      libraryViewModelProvider,
    );
    final bool isFav =
        libraryAsync.asData?.value.favourites.any(
          (Station s) => s.id == station.id,
        ) ??
        false;

    final String flag = countryFlagEmoji(station.countryCode);
    final String countryText = station.countryName.isNotEmpty
        ? '$flag ${station.countryName}'
        : flag;

    return StationTile(
      name: station.name,
      countryLabel: countryText,
      genres: station.genres
          .map((Genre g) => g.name)
          .take(2)
          .toList(growable: false),
      codec: station.codec,
      bitrateKbps: station.bitrateKbps,
      isHls: station.isHls,
      isPlaying: isPlaying,
      isFavourite: isFav,
      isWorking: station.isWorking,
      faviconUrl: station.usesFallbackLogo ? null : station.faviconUrl,
      onTap: () => context.push('/station/${station.id}'),
      onPlayTap: () {
        final PlayerViewModel player = ref.read(
          playerViewModelProvider.notifier,
        );
        if (isCurrent) {
          player.togglePlayPause();
        } else {
          player.playStation(station);
        }
      },
      onFavouriteTap: () =>
          ref.read(libraryViewModelProvider.notifier).toggleFavourite(station),
    );
  }
}
