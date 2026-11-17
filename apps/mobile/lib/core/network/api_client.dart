import 'package:dio/dio.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';

typedef TokenProvider = Future<String?> Function({bool forceRefresh});

/// Authenticated HTTP client for the PekSoft Radio Browser Node API.
///
/// Automatically attaches the Firebase ID token as `Authorization: Bearer ...`
/// and silently force-refreshes + retries once on HTTP 401.
class ApiClient {
  ApiClient({required this.getIdToken, String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl:
                  baseUrl ??
                  const String.fromEnvironment(
                    'API_BASE_URL',
                    defaultValue: 'http://10.0.2.2:4000',
                  ),
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 12),
              headers: const <String, dynamic>{
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              if (options.extra['_retriedAuth'] != true) {
                final String? token = await getIdToken(forceRefresh: false);
                if (token != null && token.isNotEmpty) {
                  options.headers['Authorization'] = 'Bearer $token';
                }
              }
              handler.next(options);
            },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final RequestOptions req = error.requestOptions;
          final bool alreadyRetried = req.extra['_retriedAuth'] == true;
          if (error.response?.statusCode == 401 && !alreadyRetried) {
            final String? refreshed = await getIdToken(forceRefresh: true);
            if (refreshed != null && refreshed.isNotEmpty) {
              req.extra['_retriedAuth'] = true;
              req.headers['Authorization'] = 'Bearer $refreshed';
              try {
                final Response<dynamic> retried = await _dio.fetch<dynamic>(
                  req,
                );
                handler.resolve(retried);
                return;
              } on DioException catch (retryErr) {
                handler.next(retryErr);
                return;
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenProvider getIdToken;
  final Dio _dio;

  Future<Result<Map<String, dynamic>>> getMe() async {
    return getJson('/v1/me');
  }

  Future<Result<Map<String, dynamic>>> getEntitlements() async {
    return getJson('/v1/entitlements');
  }

  Future<Result<Map<String, dynamic>>> verifyGooglePlayPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    return _guard(() async {
      final Response<Map<String, dynamic>> res = await _dio
          .post<Map<String, dynamic>>(
            '/v1/billing/google-play/verify',
            data: <String, dynamic>{
              'productId': productId,
              'purchaseToken': purchaseToken,
            },
          );
      return res.data ?? <String, dynamic>{};
    });
  }

  Future<Result<Map<String, dynamic>>> getJson(String path) async {
    return _guard(() async {
      final Response<Map<String, dynamic>> res = await _dio
          .get<Map<String, dynamic>>(path);
      return res.data ?? <String, dynamic>{};
    });
  }

  Future<Result<void>> deleteMe() async {
    return _guard(() async {
      await _dio.delete<void>('/v1/me');
    });
  }

  Future<Result<Map<String, dynamic>>> deltaSync(
    Map<String, dynamic> payload,
  ) async {
    return _guard(() async {
      final Response<Map<String, dynamic>> res = await _dio
          .post<Map<String, dynamic>>('/v1/sync', data: payload);
      return res.data ?? <String, dynamic>{};
    });
  }

  Future<Result<void>> submitStationReport(Map<String, dynamic> payload) async {
    return _guard(() async {
      await _dio.post<Map<String, dynamic>>('/v1/reports', data: payload);
    });
  }

  Future<Result<T>> _guard<T>(Future<T> Function() fn) async {
    try {
      return Success<T>(await fn());
    } on DioException catch (e) {
      final int? status = e.response?.statusCode;
      final dynamic data = e.response?.data;
      final String? apiMsg = data is Map<String, dynamic>
          ? (data['error'] is Map<String, dynamic>
                ? data['error']['message'] as String?
                : null)
          : null;

      if (status == 401) {
        return Failure<T>(
          AppFailure.validation(message: apiMsg ?? 'Authentication required.'),
        );
      }
      if (status == 403) {
        return Failure<T>(
          AppFailure.entitlementRequired(
            message: apiMsg ?? 'Action blocked by tier limit.',
          ),
        );
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return Failure<T>(
          AppFailure.timeout(
            message: apiMsg ?? 'Request to PekSoft API timed out.',
          ),
        );
      }
      return Failure<T>(
        AppFailure.network(
          message: apiMsg ?? 'API request failed.',
          statusCode: status,
        ),
      );
    } catch (e) {
      return Failure<T>(AppFailure.unknown(message: e.toString(), cause: e));
    }
  }
}
