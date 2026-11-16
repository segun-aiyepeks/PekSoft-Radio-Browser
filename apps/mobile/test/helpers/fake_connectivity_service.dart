import 'dart:async';

import 'package:peksoft_radio/core/network/connectivity_service.dart';

/// In-memory [ConnectivityService] fake for resilience tests.
class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({bool initialOnline = true})
    : _online = initialOnline;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _online;

  @override
  Stream<bool> get onOnlineChanged => _controller.stream;

  @override
  Future<bool> isOnline() async => _online;

  void emitOnline(bool online) {
    _online = online;
    if (!_controller.isClosed) {
      _controller.add(online);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}
