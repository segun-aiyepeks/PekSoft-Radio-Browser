import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over network connectivity status for stream auto-reconnect.
abstract interface class ConnectivityService {
  /// Broadcast stream emitting `true` when online, `false` when offline.
  Stream<bool> get onOnlineChanged;

  /// Returns whether the device currently has network connectivity.
  Future<bool> isOnline();
}

/// Production [ConnectivityService] backed by `connectivity_plus`.
class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<bool> get onOnlineChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  @override
  Future<bool> isOnline() async {
    final List<ConnectivityResult> results = await _connectivity
        .checkConnectivity();
    return _hasConnection(results);
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((ConnectivityResult r) => r != ConnectivityResult.none);
  }
}
