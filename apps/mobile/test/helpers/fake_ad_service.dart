import 'package:peksoft_radio/core/ads/ad_config.dart';
import 'package:peksoft_radio/core/ads/ad_policy.dart';
import 'package:peksoft_radio/core/ads/ad_service.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';

class FakeAdService implements AdService {
  FakeAdService({
    AdConfig? config,
    AdPolicy? policy,
    this.consentResult = AdConsentStatus.notRequired,
    this.rewardedDismissedEarly = false,
  }) : _config = config ?? const AdConfig(isDebugMode: true),
       _policy = policy ?? AdPolicy();

  final AdConfig _config;
  final AdPolicy _policy;
  final AdConsentStatus consentResult;
  final bool rewardedDismissedEarly;

  AdConsentStatus _consentStatus = AdConsentStatus.unknown;
  bool _canRequestAds = true;
  int consentFlowCalls = 0;
  int interstitialsShown = 0;
  int rewardedAdsShown = 0;

  @override
  AdConfig get config => _config;

  @override
  AdPolicy get policy => _policy;

  @override
  AdConsentStatus get consentStatus => _consentStatus;

  @override
  bool get canRequestAds => _canRequestAds;

  @override
  Future<AdConsentStatus> runConsentFlowIfRequired() async {
    consentFlowCalls += 1;
    _consentStatus = consentResult;
    _canRequestAds =
        consentResult == AdConsentStatus.notRequired ||
        consentResult == AdConsentStatus.obtained;
    return _consentStatus;
  }

  @override
  void notifyFirstSoundReached() {
    _policy.recordFirstSound();
  }

  @override
  Future<bool> showInterstitialIfEligible({
    required Entitlement entitlement,
    required String route,
    required AdBreakTrigger trigger,
  }) async {
    if (!_canRequestAds ||
        !_policy.canShowInterstitial(
          entitlement: entitlement,
          route: route,
          trigger: trigger,
        )) {
      return false;
    }
    _policy.recordInterstitialShown();
    interstitialsShown += 1;
    return true;
  }

  @override
  Future<Result<Entitlement>> showRewardedAdForPlusPass({
    required EntitlementRepository entitlementRepository,
  }) async {
    if (rewardedDismissedEarly) {
      return const Failure<Entitlement>(
        AppFailure.validation(
          message: 'Watch the full ad to unlock 24 hours of Plus features.',
        ),
      );
    }
    rewardedAdsShown += 1;
    return entitlementRepository.grantTemporaryRewardedPass(
      duration: AdPolicy.rewardedPassDuration,
    );
  }
}
