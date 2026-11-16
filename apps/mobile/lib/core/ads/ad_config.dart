import 'package:flutter/foundation.dart';

/// Build-time AdMob unit ID configuration.
///
/// Real production AdMob unit IDs are injected via `--dart-define` in CI /
/// release builds and are NEVER committed to the repository.
/// Google's official Android test ad unit IDs are used ONLY when [isDebugMode]
/// is true and no environment override is provided.
@immutable
class AdConfig {
  const AdConfig({
    this.isDebugMode = kDebugMode,
    String? bannerAdUnitId,
    String? nativeAdUnitId,
    String? interstitialAdUnitId,
    String? rewardedAdUnitId,
  }) : _bannerEnv =
           bannerAdUnitId ??
           const String.fromEnvironment('ADMOB_BANNER_AD_UNIT_ID'),
       _nativeEnv =
           nativeAdUnitId ??
           const String.fromEnvironment('ADMOB_NATIVE_AD_UNIT_ID'),
       _interstitialEnv =
           interstitialAdUnitId ??
           const String.fromEnvironment('ADMOB_INTERSTITIAL_AD_UNIT_ID'),
       _rewardedEnv =
           rewardedAdUnitId ??
           const String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID');

  /// Official Google AdMob Android test unit IDs (safe for debug builds only).
  static const String googleTestAdaptiveBannerId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String googleTestNativeAdvancedId =
      'ca-app-pub-3940256099942544/2247696110';
  static const String googleTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String googleTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  final bool isDebugMode;
  final String _bannerEnv;
  final String _nativeEnv;
  final String _interstitialEnv;
  final String _rewardedEnv;

  String? get bannerAdUnitId =>
      _resolve(_bannerEnv, debugFallback: googleTestAdaptiveBannerId);

  String? get nativeAdUnitId =>
      _resolve(_nativeEnv, debugFallback: googleTestNativeAdvancedId);

  String? get interstitialAdUnitId =>
      _resolve(_interstitialEnv, debugFallback: googleTestInterstitialId);

  String? get rewardedAdUnitId =>
      _resolve(_rewardedEnv, debugFallback: googleTestRewardedId);

  String? _resolve(String envValue, {required String debugFallback}) {
    final String trimmed = envValue.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    if (isDebugMode) {
      return debugFallback;
    }
    return null;
  }
}
