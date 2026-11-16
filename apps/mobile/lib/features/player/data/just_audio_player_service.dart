import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:peksoft_radio/features/player/data/radio_audio_handler.dart';
import 'package:peksoft_radio/features/player/domain/audio_player_service.dart';
import 'package:peksoft_radio/features/station/domain/station.dart';

/// Production [AudioPlayerService] powered by `just_audio` and `audio_service`.
class JustAudioPlayerService implements AudioPlayerService {
  JustAudioPlayerService({RadioAudioHandler? handler}) : _handler = handler {
    if (handler != null) {
      _attachHandler(handler);
    }
  }

  final StreamController<AudioPlaybackSnapshot> _eventsController =
      StreamController<AudioPlaybackSnapshot>.broadcast();

  RadioAudioHandler? _handler;
  Completer<RadioAudioHandler>? _initCompleter;
  StreamSubscription<AudioPlaybackSnapshot>? _handlerSub;
  AudioPlaybackSnapshot _currentSnapshot = const AudioPlaybackSnapshot();

  @override
  Stream<AudioPlaybackSnapshot> get playbackEvents => _eventsController.stream;

  @override
  AudioPlaybackSnapshot get currentSnapshot => _currentSnapshot;

  Future<RadioAudioHandler> _ensureHandler() async {
    if (_handler != null) return _handler!;
    if (_initCompleter != null) return _initCompleter!.future;

    final Completer<RadioAudioHandler> completer =
        Completer<RadioAudioHandler>();
    _initCompleter = completer;
    try {
      final RadioAudioHandler handler = await AudioService.init(
        builder: RadioAudioHandler.new,
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.peksoft.radio.channel.audio',
          androidNotificationChannelName: 'PekSoft Radio Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
      _handler = handler;
      _attachHandler(handler);
      completer.complete(handler);
      return handler;
    } catch (error, stackTrace) {
      _initCompleter = null;
      completer.completeError(error, stackTrace);
      rethrow;
    }
  }

  void _attachHandler(RadioAudioHandler handler) {
    _handlerSub?.cancel();
    _handlerSub = handler.snapshots.listen((AudioPlaybackSnapshot snapshot) {
      _currentSnapshot = snapshot;
      if (!_eventsController.isClosed) {
        _eventsController.add(snapshot);
      }
    });
  }

  @override
  Future<void> playStation(Station station, {String? overrideUrl}) async {
    final RadioAudioHandler handler = await _ensureHandler();
    await handler.playStation(station, overrideUrl: overrideUrl);
  }

  @override
  Future<void> pause() async {
    final RadioAudioHandler? handler = _handler;
    if (handler == null) return;
    await handler.pause();
  }

  @override
  Future<void> resume() async {
    final RadioAudioHandler? handler = _handler;
    if (handler == null) return;
    await handler.play();
  }

  @override
  Future<void> stop() async {
    final RadioAudioHandler? handler = _handler;
    if (handler == null) return;
    await handler.stop();
  }

  @override
  Future<void> setVolume(double volume) async {
    final RadioAudioHandler? handler = _handler;
    if (handler == null) return;
    await handler.setVolume(volume);
  }

  @override
  Future<void> dispose() async {
    await _handlerSub?.cancel();
    await _handler?.disposeHandler();
    await _eventsController.close();
  }
}
