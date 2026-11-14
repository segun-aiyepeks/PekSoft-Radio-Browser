import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/features/player/domain/audio_player_service.dart';
import 'package:peksoft_radio/features/player/domain/playback_state.dart'
    as domain;
import 'package:peksoft_radio/features/station/domain/station.dart';

/// `audio_service` background handler backed by `just_audio` and `audio_session`.
///
/// Manages Android foreground service media notifications, lock-screen &
/// Bluetooth AVRCP metadata/controls, audio focus with ducking, headphone
/// unplug (`becomingNoisy`) pausing, and live ICY metadata extraction.
class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler({AudioPlayer? player})
    : _player = player ?? AudioPlayer(handleInterruptions: false) {
    _init();
  }

  static const double _duckVolume = 0.25;

  final AudioPlayer _player;
  final StreamController<AudioPlaybackSnapshot> _snapshotController =
      StreamController<AudioPlaybackSnapshot>.broadcast();

  AudioPlaybackSnapshot _snapshot = const AudioPlaybackSnapshot();
  Station? _currentStation;
  double _targetVolume = 1.0;
  bool _resumeAfterInterruption = false;
  bool _audioSessionReady = false;

  StreamSubscription<PlaybackEvent>? _playbackEventSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<IcyMetadata?>? _icySub;
  StreamSubscription<void>? _noisySub;
  StreamSubscription<AudioInterruptionEvent>? _interruptionSub;

  Stream<AudioPlaybackSnapshot> get snapshots => _snapshotController.stream;
  AudioPlaybackSnapshot get currentSnapshot => _snapshot;

  void _init() {
    _playbackEventSub = _player.playbackEventStream.listen(
      _broadcastAudioServiceState,
      onError: (Object error, StackTrace stackTrace) {
        _emitSnapshot(
          _snapshot.copyWith(
            status: domain.PlaybackStatus.unavailable,
            error: AppFailure.streamPlayback(message: error.toString()),
          ),
        );
      },
    );

    _playerStateSub = _player.playerStateStream.listen((PlayerState state) {
      _broadcastAudioServiceState(_player.playbackEvent);
      final domain.PlaybackStatus nextStatus = _mapPlayerState(state);
      _emitSnapshot(
        _snapshot.copyWith(
          status: nextStatus,
          clearError: nextStatus != domain.PlaybackStatus.unavailable,
        ),
      );
    });

    _icySub = _player.icyMetadataStream.listen((IcyMetadata? metadata) {
      final String? rawTitle = metadata?.info?.title?.trim();
      if (rawTitle == null || rawTitle.isEmpty) return;
      if (rawTitle == _snapshot.icyTitle) return;

      _emitSnapshot(_snapshot.copyWith(icyTitle: rawTitle));
      _updateMediaItem(icyTitle: rawTitle);
    });
  }

  Future<void> _ensureAudioSession() async {
    if (_audioSessionReady) return;
    _audioSessionReady = true;
    final AudioSession session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _noisySub = session.becomingNoisyEventStream.listen((_) {
      // Pause immediately when headphones are unplugged or Bluetooth disconnects.
      pause();
    });

    _interruptionSub = session.interruptionEventStream.listen((
      AudioInterruptionEvent event,
    ) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(_duckVolume);
          case AudioInterruptionType.pause:
            _resumeAfterInterruption = _player.playing;
            pause();
          case AudioInterruptionType.unknown:
            _resumeAfterInterruption = false;
            pause();
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(_targetVolume);
          case AudioInterruptionType.pause:
            if (_resumeAfterInterruption) {
              _resumeAfterInterruption = false;
              play();
            }
          case AudioInterruptionType.unknown:
            _resumeAfterInterruption = false;
        }
      }
    });
  }

  Future<void> playStation(Station station, {String? overrideUrl}) async {
    _currentStation = station;
    final String streamUrl = (overrideUrl ?? station.streamUrl).trim();
    if (streamUrl.isEmpty) {
      _emitSnapshot(
        AudioPlaybackSnapshot(
          status: domain.PlaybackStatus.unavailable,
          error: const AppFailure.streamPlayback(
            message: 'Station has no playable stream URL.',
          ),
          activeUrl: streamUrl,
        ),
      );
      return;
    }

    _emitSnapshot(
      AudioPlaybackSnapshot(
        status: domain.PlaybackStatus.buffering,
        activeUrl: streamUrl,
      ),
    );

    try {
      await _ensureAudioSession();
      final AudioSession session = await AudioSession.instance;
      await session.setActive(true);
      await _player.setVolume(_targetVolume);
      _updateMediaItem();

      // AudioSource.uri supports MP3, AAC, OGG, and HLS (.m3u8) streams via ExoPlayer.
      await _player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
      await _player.play();
    } catch (error) {
      _emitSnapshot(
        _snapshot.copyWith(
          status: domain.PlaybackStatus.unavailable,
          error: AppFailure.streamPlayback(message: error.toString()),
          activeUrl: streamUrl,
        ),
      );
    }
  }

  @override
  Future<void> play() async {
    try {
      await _ensureAudioSession();
      final AudioSession session = await AudioSession.instance;
      await session.setActive(true);
      await _player.play();
    } catch (error) {
      _emitSnapshot(
        _snapshot.copyWith(
          status: domain.PlaybackStatus.unavailable,
          error: AppFailure.streamPlayback(message: error.toString()),
        ),
      );
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _resumeAfterInterruption = false;
    await _player.stop();
    mediaItem.add(null);
    _currentStation = null;
    _emitSnapshot(
      const AudioPlaybackSnapshot(status: domain.PlaybackStatus.idle),
    );
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    if (!_player.playing) {
      await stop();
    }
  }

  Future<void> setVolume(double volume) async {
    _targetVolume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_targetVolume);
  }

  Future<void> disposeHandler() async {
    await _playbackEventSub?.cancel();
    await _playerStateSub?.cancel();
    await _icySub?.cancel();
    await _noisySub?.cancel();
    await _interruptionSub?.cancel();
    await _player.dispose();
    await _snapshotController.close();
  }

  void _updateMediaItem({String? icyTitle}) {
    final Station? station = _currentStation;
    if (station == null) return;
    final Uri? artUri =
        station.faviconUrl != null && station.faviconUrl!.isNotEmpty
        ? Uri.tryParse(station.faviconUrl!)
        : null;

    mediaItem.add(
      MediaItem(
        id: station.id,
        title: icyTitle ?? station.name,
        artist: icyTitle != null
            ? station.name
            : '${station.countryName} · ${station.codec}',
        album: station.countryName,
        artUri: artUri,
        extras: <String, dynamic>{
          'stationId': station.id,
          'codec': station.codec,
          'bitrateKbps': station.bitrateKbps,
          'isHls': station.isHls,
        },
      ),
    );
  }

  void _broadcastAudioServiceState(PlaybackEvent event) {
    final bool playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: <MediaControl>[
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const <MediaAction>{
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: const <int>[0, 1],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: event.updatePosition,
        bufferedPosition: event.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  domain.PlaybackStatus _mapPlayerState(PlayerState state) {
    if (_currentStation == null) return domain.PlaybackStatus.idle;
    return switch (state.processingState) {
      ProcessingState.idle => domain.PlaybackStatus.idle,
      ProcessingState.loading ||
      ProcessingState.buffering => domain.PlaybackStatus.buffering,
      ProcessingState.ready =>
        state.playing
            ? domain.PlaybackStatus.playing
            : domain.PlaybackStatus.paused,
      ProcessingState.completed => domain.PlaybackStatus.paused,
    };
  }

  void _emitSnapshot(AudioPlaybackSnapshot next) {
    _snapshot = next;
    if (!_snapshotController.isClosed) {
      _snapshotController.add(next);
    }
  }
}
