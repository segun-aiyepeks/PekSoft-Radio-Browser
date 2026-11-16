import 'package:flutter/foundation.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Snapshot of the underlying audio engine state emitted by [AudioPlayerService].
@immutable
class AudioPlaybackSnapshot {
  const AudioPlaybackSnapshot({
    this.status = PlaybackStatus.idle,
    this.icyTitle,
    this.error,
    this.activeUrl,
  });

  final PlaybackStatus status;
  final String? icyTitle;
  final AppFailure? error;
  final String? activeUrl;

  AudioPlaybackSnapshot copyWith({
    PlaybackStatus? status,
    String? icyTitle,
    bool clearIcyTitle = false,
    AppFailure? error,
    bool clearError = false,
    String? activeUrl,
  }) {
    return AudioPlaybackSnapshot(
      status: status ?? this.status,
      icyTitle: clearIcyTitle ? null : (icyTitle ?? this.icyTitle),
      error: clearError ? null : (error ?? this.error),
      activeUrl: activeUrl ?? this.activeUrl,
    );
  }
}

/// Abstract audio engine interface for live radio playback.
///
/// Implemented in production by [JustAudioPlayerService] using `just_audio`,
/// `audio_service`, and `audio_session`, and faked in widget/unit tests.
abstract interface class AudioPlayerService {
  /// Broadcast stream of playback status, ICY metadata, and error updates.
  Stream<AudioPlaybackSnapshot> get playbackEvents;

  /// Latest emitted snapshot.
  AudioPlaybackSnapshot get currentSnapshot;

  /// Starts playing [station], optionally using [overrideUrl] (e.g. fallback).
  Future<void> playStation(Station station, {String? overrideUrl});

  /// Pauses active playback.
  Future<void> pause();

  /// Resumes paused playback.
  Future<void> resume();

  /// Stops playback and clears the active media session.
  Future<void> stop();

  /// Adjusts output volume in the range `0.0`..`1.0` (used for ducking/fade).
  Future<void> setVolume(double volume);

  /// Releases audio engine resources.
  Future<void> dispose();
}
