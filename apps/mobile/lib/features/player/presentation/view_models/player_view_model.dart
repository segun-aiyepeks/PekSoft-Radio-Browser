import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/connectivity_service.dart';
import 'package:peksoft_radio/core/normalisation/station_normaliser.dart';
import 'package:peksoft_radio/features/library/domain/song_history_entry.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/player/domain/audio_player_service.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/player/domain/stream_variant_selector.dart';
import 'package:peksoft_radio/features/profile/domain/user_settings.dart';
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
  Timer? _sleepTimer;
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
      _sleepTimer?.cancel();
      _sleepTimer = null;
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
    final Station effectiveStation = await _resolveDataSaverVariant(station);
    if (requestId != _playRequestId) return;

    state = state.copyWith(
      playback: state.playback.copyWith(
        currentStation: effectiveStation,
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
    final Future<void> recentFuture = libraryRepo.recordRecent(
      effectiveStation,
    );
    final Future<void> clickFuture = stationRepo.reportClick(
      effectiveStation.id,
    );
    final Future<Result<bool>> favFuture = libraryRepo.isFavourite(
      effectiveStation.id,
    );
    final Future<Result<List<Station>>> similarFuture = stationRepo
        .getSimilarStations(effectiveStation);

    await _playWithFailoverAndRetries(effectiveStation, requestId);
    if (requestId != _playRequestId) return;

    await Future.wait<void>(<Future<void>>[recentFuture, clickFuture]);
    ref.invalidate(libraryViewModelProvider);

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

  /// Picks a random working station from the catalog and starts playing it.
  Future<Station?> playSurpriseMe({Random? random}) async {
    final Result<List<Station>> res = await ref
        .read(catalogRepositoryProvider)
        .getTopStations(filter: const StationFilter(workingNowOnly: true));
    final List<Station> candidates = switch (res) {
      Success<List<Station>>(:final data) => data,
      Failure<List<Station>>() => const <Station>[],
    };
    if (candidates.isEmpty) return null;

    final String? currentId = state.playback.currentStation?.id;
    final List<Station> pool = candidates.length > 1 && currentId != null
        ? candidates
              .where((Station s) => s.id != currentId)
              .toList(growable: false)
        : candidates;
    final Station chosen = pool[(random ?? Random()).nextInt(pool.length)];
    await playStation(chosen);
    return chosen;
  }

  Future<Station> _resolveDataSaverVariant(Station station) async {
    final Result<UserSettings> settingsRes = await ref
        .read(settingsRepositoryProvider)
        .getSettings();
    final bool dataSaver = switch (settingsRes) {
      Success<UserSettings>(:final data) => data.dataSaver,
      Failure<UserSettings>() => false,
    };
    if (!dataSaver) return station;

    final Result<List<Station>> variantsRes = await ref
        .read(catalogRepositoryProvider)
        .searchStations(
          StationFilter(
            workingNowOnly: true,
            countryCode: station.countryCode,
            query: station.name,
          ),
        );
    final List<Station> variants = switch (variantsRes) {
      Success<List<Station>>(:final data) => data,
      Failure<List<Station>>() => const <Station>[],
    };
    return selectBitrateVariant(station, variants, dataSaver: true);
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
    _sleepTimer?.cancel();
    _sleepTimer = null;
    final AudioPlayerService audio = ref.read(audioPlayerServiceProvider);
    unawaited(audio.setVolume(1.0));
    unawaited(audio.stop());
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
    ref.invalidate(libraryViewModelProvider);
  }

  Future<void> toggleFavourite() async {
    final Station? station = state.playback.currentStation;
    if (station == null) return;
    final library = ref.read(libraryRepositoryProvider);
    final Result<void> res = state.isFavourite
        ? await library.removeFavourite(station.id)
        : await library.addFavourite(station);

    switch (res) {
      case Success<void>():
        state = state.copyWith(
          isFavourite: !state.isFavourite,
          clearError: true,
        );
        ref.invalidate(libraryViewModelProvider);
      case Failure<void>(:final error):
        state = state.copyWith(error: error);
    }
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    final AudioPlayerService audio = ref.read(audioPlayerServiceProvider);

    if (duration == null || duration <= Duration.zero) {
      unawaited(audio.setVolume(1.0));
      state = state.copyWith(
        playback: state.playback.copyWith(sleepTimerRemaining: null),
      );
      return;
    }

    unawaited(audio.setVolume(1.0));
    state = state.copyWith(
      playback: state.playback.copyWith(sleepTimerRemaining: duration),
    );

    final Duration tick = ref.read(sleepTimerTickProvider);
    final Duration fadeDuration = ref.read(sleepFadeDurationProvider);

    _sleepTimer = Timer.periodic(tick, (_) {
      final Duration? current = state.playback.sleepTimerRemaining;
      if (current == null) {
        _sleepTimer?.cancel();
        _sleepTimer = null;
        return;
      }

      final Duration next = current - tick;
      if (next <= Duration.zero) {
        _sleepTimer?.cancel();
        _sleepTimer = null;
        unawaited(audio.pause());
        unawaited(audio.setVolume(1.0));
        state = state.copyWith(
          playback: state.playback.copyWith(
            status: state.playback.currentStation == null
                ? PlaybackStatus.idle
                : PlaybackStatus.paused,
            sleepTimerRemaining: null,
          ),
        );
        return;
      }

      if (fadeDuration > Duration.zero && next <= fadeDuration) {
        final double ratio = (next.inMilliseconds / fadeDuration.inMilliseconds)
            .clamp(0.05, 1.0);
        unawaited(audio.setVolume(ratio));
      }

      state = state.copyWith(
        playback: state.playback.copyWith(sleepTimerRemaining: next),
      );
    });
  }

  void cancelSleepTimer() {
    setSleepTimer(null);
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
