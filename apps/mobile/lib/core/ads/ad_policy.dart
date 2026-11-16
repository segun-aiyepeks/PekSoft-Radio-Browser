import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';

/// Candidate moments when an interstitial could be requested.
///
/// Only natural navigation/task breaks ([completedBrowseFlow],
/// [finishedCollectionEdit], [exitedStationDetailAfterStop]) may trigger an
/// interstitial; [appLaunch], [firstPlay], and [startingPlayback] are strictly
/// blocked per UX Journey J7 and Design Principle 4.
enum AdBreakTrigger {
  appLaunch,
  firstPlay,
  startingPlayback,
  completedBrowseFlow,
  finishedCollectionEdit,
  exitedStationDetailAfterStop,
}

/// Pure-Dart policy engine enforcing PekSoft Radio Browser's ad rules
/// (UX Document Section 1 Principle 4 and Section 5 Journey J7):
/// - Nothing at all for Plus users (paid Plus or active 24h rewarded pass).
/// - No ad before first sound (`hasReachedFirstSound == true` required).
/// - Never on onboarding, auth, paywall/billing, or player-control surfaces.
/// - At most 1 interstitial per 10 minutes, and only at natural breaks.
/// - Native ad cards every 8 station rows in long lists.
class AdPolicy {
  AdPolicy({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static const Duration interstitialCooldown = Duration(minutes: 10);
  static const int nativeAdInterval = 8;
  static const Duration rewardedPassDuration = Duration(hours: 24);

  final DateTime Function() _now;

  bool _hasReachedFirstSound = false;
  DateTime? _lastInterstitialShownAt;

  bool get hasReachedFirstSound => _hasReachedFirstSound;

  DateTime? get lastInterstitialShownAt => _lastInterstitialShownAt;

  /// Marks that the listener has heard their first audio stream in the app.
  void recordFirstSound() {
    _hasReachedFirstSound = true;
  }

  /// Records that an interstitial was displayed at [timestamp] (or `_now()`).
  void recordInterstitialShown([DateTime? timestamp]) {
    _lastInterstitialShownAt = timestamp ?? _now();
  }

  /// True when [route] is an onboarding, authentication, paywall/subscription,
  /// or full-screen player / playback-control surface where ads are forbidden.
  static bool isAdBannedRoute(String route) {
    final String clean = route.trim().toLowerCase().split('?').first;
    if (clean.isEmpty || clean == '/') return true;
    const Set<String> exactBanned = <String>{
      '/splash',
      '/welcome',
      '/auth',
      '/paywall',
      '/subscription',
      '/player',
      '/now-playing',
      '/mini-player',
      '/delete-account',
    };
    if (exactBanned.contains(clean)) {
      return true;
    }
    if (clean.startsWith('/auth/') ||
        clean.startsWith('/paywall/') ||
        clean.startsWith('/subscription/') ||
        clean.startsWith('/player/')) {
      return true;
    }
    return false;
  }

  /// True when [trigger] is a natural break between tasks (never launch or play).
  static bool isNaturalBreak(AdBreakTrigger trigger) {
    return switch (trigger) {
      AdBreakTrigger.completedBrowseFlow ||
      AdBreakTrigger.finishedCollectionEdit ||
      AdBreakTrigger.exitedStationDetailAfterStop => true,
      AdBreakTrigger.appLaunch ||
      AdBreakTrigger.firstPlay ||
      AdBreakTrigger.startingPlayback => false,
    };
  }

  /// Whether an adaptive banner ad may be shown on [route].
  bool canShowBanner({
    required Entitlement entitlement,
    required String route,
    bool isNearPlayerControls = false,
    DateTime? at,
  }) {
    final DateTime timestamp = at ?? _now();
    final FeatureGate gate = FeatureGate(entitlement, now: timestamp);
    if (!gate.adsEnabled || gate.isPlus) {
      return false;
    }
    if (!_hasReachedFirstSound) {
      return false;
    }
    if (isNearPlayerControls) {
      return false;
    }
    if (isAdBannedRoute(route)) {
      return false;
    }
    return true;
  }

  /// Whether a native ad card should be inserted immediately after the
  /// 0-based station row [stationRowIndex] (i.e. after rows 7, 15, 23... =
  /// every 8 station rows).
  bool shouldInsertNativeAdAfterRow({
    required Entitlement entitlement,
    required String route,
    required int stationRowIndex,
    required int totalStationRows,
    DateTime? at,
  }) {
    if (stationRowIndex < 0 || totalStationRows < nativeAdInterval) {
      return false;
    }
    if (!canShowBanner(entitlement: entitlement, route: route, at: at)) {
      return false;
    }
    final int oneBasedRowNumber = stationRowIndex + 1;
    return oneBasedRowNumber % nativeAdInterval == 0;
  }

  /// Returns the 0-based station row indices after which a native ad card
  /// should appear for a list of [totalStationRows] stations.
  List<int> nativeAdInsertionRows({
    required Entitlement entitlement,
    required String route,
    required int totalStationRows,
    DateTime? at,
  }) {
    if (!canShowBanner(entitlement: entitlement, route: route, at: at) ||
        totalStationRows < nativeAdInterval) {
      return const <int>[];
    }
    final List<int> indices = <int>[];
    for (
      int i = nativeAdInterval - 1;
      i < totalStationRows;
      i += nativeAdInterval
    ) {
      indices.add(i);
    }
    return List<int>.unmodifiable(indices);
  }

  /// Whether an interstitial ad may be shown right now.
  bool canShowInterstitial({
    required Entitlement entitlement,
    required String route,
    required AdBreakTrigger trigger,
    DateTime? at,
  }) {
    final DateTime timestamp = at ?? _now();
    if (!isNaturalBreak(trigger)) {
      return false;
    }
    if (!canShowBanner(entitlement: entitlement, route: route, at: timestamp)) {
      return false;
    }
    final DateTime? lastShown = _lastInterstitialShownAt;
    if (lastShown != null &&
        timestamp.difference(lastShown) < interstitialCooldown) {
      return false;
    }
    return true;
  }

  /// Whether the optional rewarded ad ("Watch an ad: 24 hours of Plus features")
  /// can be offered to the user. Paid Plus subscribers do not see it.
  bool canOfferRewardedAd({required Entitlement entitlement, DateTime? at}) {
    final DateTime timestamp = at ?? _now();
    final FeatureGate gate = FeatureGate(entitlement, now: timestamp);
    return !gate.isPaidPlus;
  }
}
