import 'package:peksoft_radio/core/ads/ad_config.dart';
import 'package:peksoft_radio/core/ads/ad_policy.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';

/// User Messaging Platform (UMP) consent state for EEA/UK/GDPR compliance.
enum AdConsentStatus { unknown, notRequired, required, obtained }

/// Result of watching the optional 24-hour Plus convenience rewarded ad.
enum RewardedAdStatus { granted, dismissedBeforeReward, unavailable }

/// Abstraction over mobile ad networks (AdMob + Google UMP consent flow).
///
/// Overridden with a deterministic in-memory fake in unit and widget tests so
/// tests never touch platform channels or the network.
abstract interface class AdService {
  AdConfig get config;

  AdPolicy get policy;

  AdConsentStatus get consentStatus;

  bool get canRequestAds;

  /// Runs Google's UMP consent gathering flow at launch where required (e.g.,
  /// EEA/UK) and initializes the Mobile Ads SDK once consent permits.
  Future<AdConsentStatus> runConsentFlowIfRequired();

  /// Notifies the ad policy that the user has reached their first audio stream.
  void notifyFirstSoundReached();

  /// Attempts to display an interstitial ad if [policy] permits it for
  /// [entitlement], [route], and [trigger].
  Future<bool> showInterstitialIfEligible({
    required Entitlement entitlement,
    required String route,
    required AdBreakTrigger trigger,
  });

  /// Displays a rewarded ad that grants 24 hours of Plus convenience features
  /// on completion via [entitlementRepository].
  Future<Result<Entitlement>> showRewardedAdForPlusPass({
    required EntitlementRepository entitlementRepository,
  });
}
