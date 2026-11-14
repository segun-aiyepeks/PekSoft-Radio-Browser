import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

part 'playback_state.freezed.dart';

/// Lifecycle states of live radio stream playback.
enum PlaybackStatus {
  idle,
  buffering,
  playing,
  paused,
  reconnecting,
  unavailable,
}

/// Immutable audio player domain state.
@freezed
abstract class PlaybackState with _$PlaybackState {
  const factory PlaybackState({
    @Default(PlaybackStatus.idle) PlaybackStatus status,
    Station? currentStation,
    String? icyTitle,
    Duration? sleepTimerRemaining,
    AppFailure? error,
  }) = _PlaybackState;
}
