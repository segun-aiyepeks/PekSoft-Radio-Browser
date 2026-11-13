import 'package:dio/dio.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_click_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_country_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_language_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_station_dto.dart';
import 'package:peksoft_radio/core/network/dto/radio_browser_tag_dto.dart';
import 'package:peksoft_radio/core/network/radio_browser_mirror_service.dart';

/// Dio-based client for the community Radio Browser API.
///
/// Implements Radio Browser etiquette from `Agents.md`:
/// - Random mirror selection with 24-hour mirror cache
/// - Failover across mirrors + exponential back-off retries
/// - Explicit `User-Agent: PekSoftRadioBrowser/<version>` header
/// - Connect/receive timeouts and click reporting (`/json/url/{uuid}`)
class RadioBrowserClient {
  RadioBrowserClient({
    Dio? dio,
    RadioBrowserMirrorService? mirrorService,
    String appVersion = '1.0.0',
    this._maxRetriesPerMirror = 1,
    this._initialBackoff = const Duration(milliseconds: 250),
    Future<void> Function(Duration)? delay,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 6),
               receiveTimeout: const Duration(seconds: 10),
               headers: <String, Object?>{
                 'User-Agent': 'PekSoftRadioBrowser/$appVersion',
                 'Accept': 'application/json',
               },
             ),
           ),
       _delay = delay ?? Future<void>.delayed {
    _dio.options.connectTimeout ??= const Duration(seconds: 6);
    _dio.options.receiveTimeout ??= const Duration(seconds: 10);
    _dio.options.headers['User-Agent'] = 'PekSoftRadioBrowser/$appVersion';
    _dio.options.headers['Accept'] = 'application/json';
    _mirrorService = mirrorService ?? RadioBrowserMirrorService(dio: _dio);
  }

  final Dio _dio;
  late final RadioBrowserMirrorService _mirrorService;
  final int _maxRetriesPerMirror;
  final Duration _initialBackoff;
  final Future<void> Function(Duration) _delay;

  Future<Result<List<RadioBrowserCountryDto>>> getCountries() async {
    return _getList(
      path: '/json/countries',
      queryParameters: const <String, Object?>{
        'order': 'stationcount',
        'reverse': 'true',
      },
      fromJson: RadioBrowserCountryDto.fromJson,
    );
  }

  Future<Result<List<RadioBrowserTagDto>>> getTags({int limit = 500}) async {
    return _getList(
      path: '/json/tags',
      queryParameters: <String, Object?>{
        'order': 'stationcount',
        'reverse': 'true',
        'limit': limit,
      },
      fromJson: RadioBrowserTagDto.fromJson,
    );
  }

  Future<Result<List<RadioBrowserLanguageDto>>> getLanguages({
    int limit = 200,
  }) async {
    return _getList(
      path: '/json/languages',
      queryParameters: <String, Object?>{
        'order': 'stationcount',
        'reverse': 'true',
        'limit': limit,
      },
      fromJson: RadioBrowserLanguageDto.fromJson,
    );
  }

  Future<Result<List<RadioBrowserStationDto>>> getTopClickStations({
    int limit = 150,
  }) async {
    return _getList(
      path: '/json/stations/topclick/$limit',
      fromJson: RadioBrowserStationDto.fromJson,
    );
  }

  Future<Result<List<RadioBrowserStationDto>>> searchStations({
    String? name,
    String? countryCode,
    String? tag,
    String? language,
    String? codec,
    int? bitrateMin,
    bool hideBroken = true,
    String order = 'clickcount',
    bool reverse = true,
    int limit = 50,
    int offset = 0,
  }) async {
    final Map<String, Object?> params = <String, Object?>{
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (countryCode != null && countryCode.trim().isNotEmpty)
        'countrycode': countryCode.trim().toUpperCase(),
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim().toLowerCase(),
      if (language != null && language.trim().isNotEmpty)
        'language': language.trim(),
      if (codec != null && codec.trim().isNotEmpty) 'codec': codec.trim(),
      if (bitrateMin != null && bitrateMin > 0) 'bitrateMin': bitrateMin,
      'hidebroken': hideBroken.toString(),
      'order': order,
      'reverse': reverse.toString(),
      'limit': limit,
      'offset': offset,
    };

    return _getList(
      path: '/json/stations/search',
      queryParameters: params,
      fromJson: RadioBrowserStationDto.fromJson,
    );
  }

  Future<Result<List<RadioBrowserStationDto>>> getStationsByUuids(
    List<String> uuids,
  ) async {
    if (uuids.isEmpty) {
      return const Success<List<RadioBrowserStationDto>>(
        <RadioBrowserStationDto>[],
      );
    }
    return _getList(
      path: '/json/stations/byuuid',
      queryParameters: <String, Object?>{'uuids': uuids.join(',')},
      fromJson: RadioBrowserStationDto.fromJson,
    );
  }

  Future<Result<RadioBrowserClickDto>> reportClick(String stationUuid) async {
    if (stationUuid.trim().isEmpty) {
      return const Failure<RadioBrowserClickDto>(
        AppFailure.validation(message: 'Station UUID is required.'),
      );
    }
    final Result<dynamic> result = await _getWithMirrorFailover(
      '/json/url/${Uri.encodeComponent(stationUuid.trim())}',
    );
    return result.when(
      success: (data) {
        if (data is Map<String, dynamic>) {
          return Success<RadioBrowserClickDto>(
            RadioBrowserClickDto.fromJson(data),
          );
        }
        return const Failure<RadioBrowserClickDto>(
          AppFailure.network(message: 'Unexpected click response format.'),
        );
      },
      failure: Failure<RadioBrowserClickDto>.new,
    );
  }

  Future<Result<List<T>>> _getList<T>({
    required String path,
    Map<String, Object?>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    final Result<dynamic> result = await _getWithMirrorFailover(
      path,
      queryParameters: queryParameters,
    );
    return result.when(
      success: (data) {
        if (data is! List<dynamic>) {
          return const Failure<List<Never>>(
                AppFailure.network(message: 'Expected JSON array response.'),
              )
              as Result<List<T>>;
        }
        final List<T> parsed = <T>[];
        for (final dynamic item in data) {
          if (item is Map<String, dynamic>) {
            parsed.add(fromJson(item));
          }
        }
        return Success<List<T>>(parsed);
      },
      failure: Failure<List<T>>.new,
    );
  }

  Future<Result<dynamic>> _getWithMirrorFailover(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    final List<String> mirrors = await _mirrorService.getOrderedMirrors();
    AppFailure? lastFailure;

    for (final String mirror in mirrors) {
      for (int attempt = 0; attempt <= _maxRetriesPerMirror; attempt++) {
        if (attempt > 0) {
          final Duration wait = _initialBackoff * (1 << (attempt - 1));
          await _delay(wait);
        }
        try {
          final Response<dynamic> response = await _dio.get<dynamic>(
            'https://$mirror$path',
            queryParameters: queryParameters,
          );
          return Success<dynamic>(response.data);
        } on DioException catch (e) {
          lastFailure = _mapDioException(e);
          if (!_isRetryable(e)) {
            return Failure<dynamic>(lastFailure);
          }
        } catch (e) {
          lastFailure = AppFailure.unknown(
            message: 'Unexpected network error.',
            cause: e,
          );
        }
      }
    }

    return Failure<dynamic>(
      lastFailure ??
          const AppFailure.mirrorUnavailable(
            message: 'All Radio Browser mirrors are unavailable.',
          ),
    );
  }

  bool _isRetryable(DioException error) {
    final int? status = error.response?.statusCode;
    if (status != null && status >= 400 && status < 500 && status != 429) {
      return false;
    }
    return true;
  }

  AppFailure _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const AppFailure.timeout(
        message: 'Radio Browser request timed out.',
      );
    }
    return AppFailure.network(
      message: error.message ?? 'Radio Browser request failed.',
      statusCode: error.response?.statusCode,
    );
  }
}
