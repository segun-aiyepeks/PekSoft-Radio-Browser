/// Canonical Section 11 analytics event names from `docs/ux-document.md`.
abstract final class AnalyticsEvents {
  static const String stationPlay = 'station_play';
  static const String stationFail = 'station_fail';
  static const String favoriteAdd = 'favorite_add';
  static const String paywallView = 'paywall_view';
  static const String purchaseSuccess = 'purchase_success';
  static const String firstAudioReached = 'first_audio_reached';
  static const String adRewardedCompleted = 'ad_rewarded_completed';
  static const String restorePurchases = 'restore_purchases';
}

/// Keys that must never appear in analytics events or Crashlytics logs.
const Set<String> _forbiddenPiiKeys = <String>{
  'email',
  'user_email',
  'name',
  'display_name',
  'displayname',
  'uid',
  'user_id',
  'userid',
  'firebase_uid',
  'phone',
  'phone_number',
  'token',
  'id_token',
  'password',
};

final RegExp _emailLikePattern = RegExp(r'\S+@\S+\.\S+');

/// Strips any personal data (PII keys or email-like strings) from analytics
/// parameters so no personal data ever leaves the device in telemetry.
Map<String, Object> sanitizeAnalyticsParams(Map<String, Object?> raw) {
  final Map<String, Object> clean = <String, Object>{};
  for (final MapEntry<String, Object?> entry in raw.entries) {
    final String keyLower = entry.key.trim().toLowerCase();
    if (keyLower.isEmpty || _forbiddenPiiKeys.contains(keyLower)) {
      continue;
    }
    final Object? value = entry.value;
    if (value == null) continue;
    if (value is String) {
      if (_emailLikePattern.hasMatch(value)) {
        continue;
      }
      clean[entry.key] = value.length > 100 ? value.substring(0, 100) : value;
    } else if (value is num || value is bool) {
      clean[entry.key] = value;
    }
  }
  return Map<String, Object>.unmodifiable(clean);
}

/// Abstraction over Firebase Analytics + Crashlytics using the Section 11
/// event taxonomy, strict PII scrubbing, and consent enforcement.
abstract interface class AnalyticsService {
  bool get consentGranted;

  /// Updates analytics & crash collection consent from Google UMP / settings.
  /// When [granted] is `false`, all event logging and crash reporting is
  /// disabled and future events are dropped.
  Future<void> setConsentGranted(bool granted);

  Future<void> logEvent(
    String name, {
    Map<String, Object?> parameters = const <String, Object?>{},
  });

  Future<void> logStationPlay({
    required String stationId,
    required String countryCode,
    required String codec,
    required int bitrateKbps,
    bool isHls = false,
  });

  Future<void> logStationFail({
    required String stationId,
    required String countryCode,
    required String reason,
  });

  Future<void> logFavoriteAdd({
    required String stationId,
    required String countryCode,
  });

  Future<void> logPaywallView({required String trigger});

  Future<void> logPurchaseSuccess({
    required String productId,
    required String source,
  });

  Future<void> logRewardedAdCompleted();

  Future<void> logRestorePurchases({required bool restored});

  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });
}
