import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:peksoft_radio/core/analytics/analytics_service.dart';

/// Production [AnalyticsService] backed by Firebase Analytics & Crashlytics.
///
/// Respects [consentGranted] before forwarding any event or crash report and
/// strips all personal data via [sanitizeAnalyticsParams].
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({
    FirebaseAnalytics? analytics,
    FirebaseCrashlytics? crashlytics,
    bool initialConsent = false,
  }) : _analyticsOverride = analytics,
       _crashlyticsOverride = crashlytics,
       _consentGranted = initialConsent;

  final FirebaseAnalytics? _analyticsOverride;
  final FirebaseCrashlytics? _crashlyticsOverride;
  bool _consentGranted;

  FirebaseAnalytics? get _analytics {
    if (_analyticsOverride != null) return _analyticsOverride;
    try {
      return FirebaseAnalytics.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseCrashlytics? get _crashlytics {
    if (_crashlyticsOverride != null) return _crashlyticsOverride;
    try {
      return FirebaseCrashlytics.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get consentGranted => _consentGranted;

  @override
  Future<void> setConsentGranted(bool granted) async {
    _consentGranted = granted;
    try {
      await _analytics?.setAnalyticsCollectionEnabled(granted);
    } catch (_) {}
    try {
      await _crashlytics?.setCrashlyticsCollectionEnabled(granted);
    } catch (_) {}
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    if (!_consentGranted) return;
    final Map<String, Object> clean = sanitizeAnalyticsParams(parameters);
    try {
      await _analytics?.logEvent(name: name, parameters: clean);
    } catch (_) {}
  }

  @override
  Future<void> logStationPlay({
    required String stationId,
    required String countryCode,
    required String codec,
    required int bitrateKbps,
    bool isHls = false,
  }) {
    return logEvent(
      AnalyticsEvents.stationPlay,
      parameters: <String, Object?>{
        'station_id': stationId,
        'country_code': countryCode,
        'codec': codec,
        'bitrate_kbps': bitrateKbps,
        'is_hls': isHls,
      },
    );
  }

  @override
  Future<void> logStationFail({
    required String stationId,
    required String countryCode,
    required String reason,
  }) {
    return logEvent(
      AnalyticsEvents.stationFail,
      parameters: <String, Object?>{
        'station_id': stationId,
        'country_code': countryCode,
        'reason': reason,
      },
    );
  }

  @override
  Future<void> logFavoriteAdd({
    required String stationId,
    required String countryCode,
  }) {
    return logEvent(
      AnalyticsEvents.favoriteAdd,
      parameters: <String, Object?>{
        'station_id': stationId,
        'country_code': countryCode,
      },
    );
  }

  @override
  Future<void> logPaywallView({required String trigger}) {
    return logEvent(
      AnalyticsEvents.paywallView,
      parameters: <String, Object?>{'trigger': trigger},
    );
  }

  @override
  Future<void> logPurchaseSuccess({
    required String productId,
    required String source,
  }) {
    return logEvent(
      AnalyticsEvents.purchaseSuccess,
      parameters: <String, Object?>{'product_id': productId, 'source': source},
    );
  }

  @override
  Future<void> logRewardedAdCompleted() {
    return logEvent(AnalyticsEvents.adRewardedCompleted);
  }

  @override
  Future<void> logRestorePurchases({required bool restored}) {
    return logEvent(
      AnalyticsEvents.restorePurchases,
      parameters: <String, Object?>{'restored': restored},
    );
  }

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_consentGranted) return;
    try {
      await _crashlytics?.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (_) {}
  }
}
