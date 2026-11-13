import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peksoft_radio/core/widgets/widgets.dart';
import 'package:peksoft_radio/mock/mock.dart';

/// Reusable wrapper connecting [StationTile] to [mockSessionController] for
/// Phase 1 UI-only play/pause, favourite toggles, and navigation to
/// [StationDetailScreen].
class MockStationTile extends StatelessWidget {
  const MockStationTile({super.key, required this.station});

  final MockStation station;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: mockSessionController,
      builder: (context, _) {
        final bool isCurrent =
            mockSessionController.currentStation.id == station.id;
        final bool isPlaying =
            isCurrent &&
            mockSessionController.playbackStatus == MockPlaybackStatus.playing;
        final bool isFav = mockSessionController.isFavourite(station.id);

        return StationTile(
          name: station.name,
          countryLabel: '${station.flagEmoji} ${station.country}',
          genres: station.genres,
          codec: station.codec,
          bitrateKbps: station.bitrateKbps,
          isHls: station.isHls,
          isPlaying: isPlaying,
          isFavourite: isFav,
          isWorking: station.isWorking,
          faviconUrl: station.faviconUrl,
          onTap: () => context.push('/station/${station.id}'),
          onPlayTap: () {
            if (isCurrent) {
              mockSessionController.togglePlayPause();
            } else {
              mockSessionController.playStation(station);
            }
          },
          onFavouriteTap: () =>
              mockSessionController.toggleFavourite(station.id),
        );
      },
    );
  }
}
