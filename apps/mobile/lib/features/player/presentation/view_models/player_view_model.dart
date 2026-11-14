import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Immutable state for [MiniPlayerSlot], [NowPlayingScreen] (`/player`),
/// [SleepTimerSheet], and [ReportStationSheet].
@immutable
class PlayerState {
  const PlayerState({
    this.playback = const PlaybackState(),
    this.isFavourite = false,
    this.similarStations = const <Station>[],
    this.reportSubmitted = false,
    this.error,
  });

  final PlaybackState playback;
  final bool isFavourite;
  final List<Station> similarStations;
  final bool reportSubmitted;
  final AppFailure? error;

  PlayerState copyWith({
    PlaybackState? playback,
    bool? isFavourite,
    List<Station>? similarStations,
    bool? reportSubmitted,
    AppFailure? error,
    bool clearError = false,
  }) {
    return PlayerState(
      playback: playback ?? this.playback,
      isFavourite: isFavourite ?? this.isFavourite,
      similarStations: similarStations ?? this.similarStations,
      reportSubmitted: reportSubmitted ?? this.reportSubmitted,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Shared ViewModel for Mini-Player, Now Playing, Sleep Timer, and Report sheets.
class PlayerViewModel extends Notifier<PlayerState> {
  @override
  PlayerState build() => const PlayerState();

  Future<void> playStation(Station station) async {
    state = state.copyWith(
      playback: state.playback.copyWith(
        currentStation: station,
        status: PlaybackStatus.buffering,
        icyTitle: null,
        error: null,
      ),
      reportSubmitted: false,
      clearError: true,
    );

    final stationRepo = ref.read(stationRepositoryProvider);
    final libraryRepo = ref.read(libraryRepositoryProvider);

    await libraryRepo.recordRecent(station);
    await stationRepo.reportClick(station.id);

    final Result<bool> favRes = await libraryRepo.isFavourite(station.id);
    final Result<List<Station>> similarRes = await stationRepo
        .getSimilarStations(station);

    state = state.copyWith(
      playback: state.playback.copyWith(status: PlaybackStatus.playing),
      isFavourite: switch (favRes) {
        Success<bool>(:final data) => data,
        Failure<bool>() => false,
      },
      similarStations: switch (similarRes) {
        Success<List<Station>>(:final data) => data,
        Failure<List<Station>>() => const <Station>[],
      },
    );
  }

  void togglePlayPause() {
    final PlaybackStatus current = state.playback.status;
    if (state.playback.currentStation == null) return;
    final PlaybackStatus next = current == PlaybackStatus.playing
        ? PlaybackStatus.paused
        : PlaybackStatus.playing;
    state = state.copyWith(playback: state.playback.copyWith(status: next));
  }

  void stop() {
    state = const PlayerState();
  }

  void setPlaybackStatus(PlaybackStatus status, {AppFailure? error}) {
    state = state.copyWith(
      playback: state.playback.copyWith(status: status, error: error),
    );
  }

  Future<void> updateTrackTitle(String title) async {
    final Station? station = state.playback.currentStation;
    if (station == null || title.trim().isEmpty) return;
    final String clean = title.trim();
    state = state.copyWith(playback: state.playback.copyWith(icyTitle: clean));
    await ref
        .read(libraryRepositoryProvider)
        .logSongHistory(
          SongHistoryEntry(
            id: '${station.id}-${DateTime.now().microsecondsSinceEpoch}',
            stationId: station.id,
            stationName: station.name,
            trackTitle: clean,
            playedAt: DateTime.now(),
          ),
        );
  }

  Future<void> toggleFavourite() async {
    final Station? station = state.playback.currentStation;
    if (station == null) return;
    final library = ref.read(libraryRepositoryProvider);
    final Result<void> res = state.isFavourite
        ? await library.removeFavourite(station.id)
        : await library.addFavourite(station);

    state = switch (res) {
      Success<void>() => state.copyWith(
        isFavourite: !state.isFavourite,
        clearError: true,
      ),
      Failure<void>(:final error) => state.copyWith(error: error),
    };
  }

  void setSleepTimer(Duration? duration) {
    state = state.copyWith(
      playback: state.playback.copyWith(sleepTimerRemaining: duration),
    );
  }

  void cancelSleepTimer() {
    state = state.copyWith(
      playback: state.playback.copyWith(sleepTimerRemaining: null),
    );
  }

  void reportCurrentStation(String reason) {
    if (state.playback.currentStation == null || reason.trim().isEmpty) return;
    state = state.copyWith(reportSubmitted: true);
  }
}

final NotifierProvider<PlayerViewModel, PlayerState> playerViewModelProvider =
    NotifierProvider<PlayerViewModel, PlayerState>(PlayerViewModel.new);
