import 'package:peksoft_radio/core/analytics/analytics_service.dart';

class RecordedAnalyticsEvent {
  const RecordedAnalyticsEvent(this.name, this.parameters);

  final String name;
  final Map<String, Object> parameters;
}

class FakeAnalyticsService implements AnalyticsService {
  FakeAnalyticsService({bool initialConsent = true})
    : _consentGranted = initialConsent;

  bool _consentGranted;
  final List<RecordedAnalyticsEvent> events = <RecordedAnalyticsEvent>[];
  final List<Object> recordedErrors = <Object>[];

  @override
  bool get consentGranted => _consentGranted;

  @override
  Future<void> setConsentGranted(bool granted) async {
    _consentGranted = granted;
  }

  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    if (!_consentGranted) return;
    events.add(
      RecordedAnalyticsEvent(name, sanitizeAnalyticsParams(parameters)),
    );
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
    recordedErrors.add(error);
  }
}
