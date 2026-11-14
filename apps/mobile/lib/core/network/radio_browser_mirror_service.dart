import 'dart:math';

import 'package:dio/dio.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_server_dto.dart';

/// Discovers and caches Radio Browser API mirrors for 24 hours.
///
/// Primary discovery uses `GET https://all.api.radio-browser.info/json/servers`
/// (verified in `docs/api-spike.md` as the best Android-compatible method),
/// falling back to known hostnames if discovery is unreachable.
class RadioBrowserMirrorService {
  RadioBrowserMirrorService({
    required this._dio,
    Random? random,
    DateTime Function()? now,
    this._cacheTtl = const Duration(hours: 24),
  }) : _random = random ?? Random(),
       _now = now ?? DateTime.now;

  static const String discoveryUrl =
      'https://all.api.radio-browser.info/json/servers';

  static const List<String> fallbackMirrors = <String>[
    'de1.api.radio-browser.info',
    'all.api.radio-browser.info',
  ];

  final Dio _dio;
  final Random _random;
  final DateTime Function() _now;
  final Duration _cacheTtl;

  List<String>? _cachedMirrors;
  DateTime? _cachedAt;

  /// Returns an ordered list of mirrors starting from a randomly chosen mirror
  /// so requests distribute fairly and callers can fail over sequentially.
  Future<List<String>> getOrderedMirrors({bool forceRefresh = false}) async {
    final List<String> mirrors = await _loadMirrors(forceRefresh: forceRefresh);
    if (mirrors.length <= 1) return List<String>.unmodifiable(mirrors);

    final int startIndex = _random.nextInt(mirrors.length);
    return List<String>.unmodifiable(<String>[
      ...mirrors.sublist(startIndex),
      ...mirrors.sublist(0, startIndex),
    ]);
  }

  Future<List<String>> _loadMirrors({required bool forceRefresh}) async {
    final DateTime current = _now();
    if (!forceRefresh &&
        _cachedMirrors != null &&
        _cachedAt != null &&
        current.difference(_cachedAt!) < _cacheTtl) {
      return _cachedMirrors!;
    }

    try {
      final Response<dynamic> response = await _dio.get<dynamic>(discoveryUrl);
      final List<dynamic> rows = response.data is List<dynamic>
          ? response.data as List<dynamic>
          : const <dynamic>[];

      final Set<String> uniqueNames = <String>{};
      for (final dynamic item in rows) {
        if (item is Map<String, dynamic>) {
          final RadioBrowserServerDto dto = RadioBrowserServerDto.fromJson(
            item,
          );
          if (dto.name.trim().isNotEmpty) {
            uniqueNames.add(dto.name.trim());
          }
        }
      }

      final List<String> discovered = uniqueNames.isNotEmpty
          ? uniqueNames.toList()
          : fallbackMirrors;
      _cachedMirrors = discovered;
      _cachedAt = current;
      return discovered;
    } catch (_) {
      _cachedMirrors = fallbackMirrors;
      _cachedAt = current;
      return fallbackMirrors;
    }
  }
}
