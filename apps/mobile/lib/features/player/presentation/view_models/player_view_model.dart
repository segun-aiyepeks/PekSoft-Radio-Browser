import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/connectivity_service.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/player/domain/audio_player_service.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Alias matching the Phase 3 specification name (`PlaybackViewModel`).
typedef PlaybackViewModel = PlayerViewModel;

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
  StreamSubscription<AudioPlaybackSnapshot>? _audioSub;
  StreamSubscription<bool>? _connectivitySub;
  int _playRequestId = 0;
  bool _isRecovering = false;
  bool _wasOffline = false;

  @override
  PlayerState build() {
    final AudioPlayerService audio = ref.watch(audioPlayerServiceProvider);
    final ConnectivityService connectivity = ref.watch(
      connectivityServiceProvider,
    );

    _audioSub?.cancel();
    _audioSub = audio.playbackEvents.listen(_onAudioSnapshot);

    _connectivitySub?.cancel();
    _connectivitySub = connectivity.onOnlineChanged.listen(_onConnectivity);

    ref.onDispose(() {
      _audioSub?.cancel();
      _audioSub = null;
      _connectivitySub?.cancel();
      _connectivitySub = null;
    });
    return const PlayerState();
  }

  void _onConnectivity(bool isOnline) {
    if (!isOnline) {
      _wasOffline = true;
      return;
    }
    final Station? station = state.playback.currentStation;
    final PlaybackStatus status = state.playback.status;
    final bool shouldReconnect =
        _wasOffline ||
        status == PlaybackStatus.unavailable ||
        status == PlaybackStatus.reconnecting;
    _wasOffline = false;

    if (station != null && shouldReconnect && !_isRecovering) {
      unawaited(playStation(station));
    }
  }

  void _onAudioSnapshot(AudioPlaybackSnapshot snapshot) {
    if (state.playback.currentStation == null) return;
    if (_isRecovering && snapshot.status == PlaybackStatus.unavailable) {
      // Handled inside _playWithFailoverAndRetries.
      return;
    }

    if (snapshot.status == PlaybackStatus.unavailable && !_isRecovering) {
      final Station station = state.playback.currentStation!;
      final int requestId = ++_playRequestId;
      unawaited(_recoverMidStream(station, requestId));
      return;
    }

    state = state.copyWith(
      playback: state.playback.copyWith(
        status: snapshot.status,
        error: snapshot.error,
      ),
      error: snapshot.error,
      clearError: snapshot.error == null,
    );

    final String? title = snapshot.icyTitle?.trim();
    if (title != null && title.isNotEmpty && title != state.playback.icyTitle) {
      unawaited(updateTrackTitle(title));
    }
  }

  Future<void> playStation(Station station) async {
    final int requestId = ++_playRequestId;
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

    // Report a click to Radio Browser on every play and load metadata in parallel.
    final Future<void> recentFuture = libraryRepo.recordRecent(station);
    final Future<void> clickFuture = stationRepo.reportClick(station.id);
    final Future<Result<bool>> favFuture = libraryRepo.isFavourite(station.id);
    final Future<Result<List<Station>>> similarFuture = stationRepo
        .getSimilarStations(station);

    await _playWithFailoverAndRetries(station, requestId);
    if (requestId != _playRequestId) return;

    await Future.wait<void>(<Future<void>>[recentFuture, clickFuture]);
    final Result<bool> favRes = await favFuture;
    final Result<List<Station>> similarRes = await similarFuture;
    if (requestId != _playRequestId) return;

    state = state.copyWith(
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

  Future<void> _recoverMidStream(Station station, int requestId) async {
    await _playWithFailoverAndRetries(station, requestId, skipInitial: true);
  }

  Future<void> _playWithFailoverAndRetries(
    Station station,
    int requestId, {
    bool skipInitial = false,
  }) async {
    _isRecovering = true;
    final AudioPlayerService audio = ref.read(audioPlayerServiceProvider);
    final List<Duration> retryDelays = ref.read(playbackRetryDelaysProvider);

    try {
      if (!skipInitial) {
        final bool connected = await _tryPrimaryThenFallback(audio, station);
        if (requestId != _playRequestId) return;
        if (connected) {
          _markPlaying(audio);
          return;
        }
      }

      for (int attempt = 0; attempt < retryDelays.length; attempt++) {
        if (requestId != _playRequestId) return;
        state = state.copyWith(
          playback: state.playback.copyWith(
            status: PlaybackStatus.reconnecting,
            error: null,
          ),
          clearError: true,
        );

        final Duration delay = retryDelays[attempt];
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
        if (requestId != _playRequestId) return;

        final bool connected = await _tryPrimaryThenFallback(audio, station);
        if (requestId != _playRequestId) return;
        if (connected) {
          _markPlaying(audio);
          return;
        }
      }

      final AppFailure friendlyError = AppFailure.streamPlayback(
        message:
            'Could not connect to ${station.name}. Try a similar station below or tap Retry.',
      );
      state = state.copyWith(
        playback: state.playback.copyWith(
          status: PlaybackStatus.unavailable,
          error: friendlyError,
        ),
        error: friendlyError,
      );
    } finally {
      if (requestId == _playRequestId) {
        _isRecovering = false;
      }
    }
  }

  Future<bool> _tryPrimaryThenFallback(
    AudioPlayerService audio,
    Station station,
  ) async {
    if (await _attemptUrl(audio, station)) {
      return true;
    }
    final String? fallback = station.fallbackStreamUrl?.trim();
    if (fallback != null &&
        fallback.isNotEmpty &&
        fallback != station.streamUrl.trim()) {
      return _attemptUrl(audio, station, overrideUrl: fallback);
    }
    return false;
  }

  Future<bool> _attemptUrl(
    AudioPlayerService audio,
    Station station, {
    String? overrideUrl,
  }) async {
    try {
      await audio.playStation(station, overrideUrl: overrideUrl);
      return audio.currentSnapshot.status != PlaybackStatus.unavailable;
    } catch (_) {
      return false;
    }
  }

  void _markPlaying(AudioPlayerService audio) {
    final PlaybackStatus snapshotStatus = audio.currentSnapshot.status;
    final PlaybackStatus resolvedStatus = snapshotStatus == PlaybackStatus.idle
        ? PlaybackStatus.playing
        : snapshotStatus;
    state = state.copyWith(
      playback: state.playback.copyWith(status: resolvedStatus, error: null),
      clearError: true,
    );
  }

  void togglePlayPause() {
    final Station? station = state.playback.currentStation;
    if (station == null) return;
    final AudioPlayerService audio = ref.read(audioPlayerServiceProvider);
    final PlaybackStatus current = state.playback.status;
    if (current == PlaybackStatus.playing) {
      state = state.copyWith(
        playback: state.playback.copyWith(status: PlaybackStatus.paused),
      );
      unawaited(audio.pause());
    } else if (current == PlaybackStatus.unavailable) {
      unawaited(playStation(station));
    } else {
      state = state.copyWith(
        playback: state.playback.copyWith(status: PlaybackStatus.playing),
      );
      unawaited(audio.resume());
    }
  }

  void stop() {
    _playRequestId += 1;
    _isRecovering = false;
    unawaited(ref.read(audioPlayerServiceProvider).stop());
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
    final Station? station = state.playback.currentStation;
    if (station == null || reason.trim().isEmpty) return;
    state = state.copyWith(reportSubmitted: true);
    unawaited(
      ref
          .read(reportQueueRepositoryProvider)
          .enqueueReport(station: station, reason: reason),
    );
  }
}

final NotifierProvider<PlayerViewModel, PlayerState> playerViewModelProvider =
    NotifierProvider<PlayerViewModel, PlayerState>(PlayerViewModel.new);

/// Alias matching the Phase 3 specification name (`playbackViewModelProvider`).
final NotifierProvider<PlayerViewModel, PlayerState> playbackViewModelProvider =
    playerViewModelProvider;
