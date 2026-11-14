import 'dart:async';

import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/features/player/domain/audio_player_service.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// In-memory [AudioPlayerService] fake for unit and widget tests.
class FakeAudioPlayerService implements AudioPlayerService {
  final StreamController<AudioPlaybackSnapshot> _controller =
      StreamController<AudioPlaybackSnapshot>.broadcast();

  AudioPlaybackSnapshot _current = const AudioPlaybackSnapshot();
  Station? lastPlayedStation;
  String? lastOverrideUrl;
  double volume = 1.0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int stopCalls = 0;
  bool failNextPlay = false;

  @override
  Stream<AudioPlaybackSnapshot> get playbackEvents => _controller.stream;

  @override
  AudioPlaybackSnapshot get currentSnapshot => _current;

  @override
  Future<void> playStation(Station station, {String? overrideUrl}) async {
    lastPlayedStation = station;
    lastOverrideUrl = overrideUrl;
    if (failNextPlay) {
      failNextPlay = false;
      _emit(
        AudioPlaybackSnapshot(
          status: PlaybackStatus.unavailable,
          error: const AppFailure.streamPlayback(
            message: 'Simulated stream failure',
          ),
          activeUrl: overrideUrl ?? station.streamUrl,
        ),
      );
      return;
    }
    _emit(
      AudioPlaybackSnapshot(
        status: PlaybackStatus.playing,
        activeUrl: overrideUrl ?? station.streamUrl,
      ),
    );
  }

  @override
  Future<void> pause() async {
    pauseCalls += 1;
    _emit(_current.copyWith(status: PlaybackStatus.paused));
  }

  @override
  Future<void> resume() async {
    resumeCalls += 1;
    _emit(_current.copyWith(status: PlaybackStatus.playing));
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _emit(const AudioPlaybackSnapshot(status: PlaybackStatus.idle));
  }

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume.clamp(0.0, 1.0);
  }

  void emitIcyTitle(String title) {
    _emit(_current.copyWith(icyTitle: title));
  }

  void emitStatus(PlaybackStatus status, {AppFailure? error}) {
    _emit(_current.copyWith(status: status, error: error));
  }

  void _emit(AudioPlaybackSnapshot snapshot) {
    _current = snapshot;
    if (!_controller.isClosed) {
      _controller.add(snapshot);
    }
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}
