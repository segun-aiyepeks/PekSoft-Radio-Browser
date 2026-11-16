import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:peksoft_radio/core/ads/ad_config.dart';
import 'package:peksoft_radio/core/ads/ad_policy.dart';
import 'package:peksoft_radio/core/ads/ad_service.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';

/// Production [AdService] backed by `google_mobile_ads` and Google's User
/// Messaging Platform (UMP) consent flow.
class AdMobAdService implements AdService {
  AdMobAdService({
    AdConfig? config,
    AdPolicy? policy,
    this.isSupportedPlatform = true,
  }) : _config = config ?? const AdConfig(),
       _policy = policy ?? AdPolicy();

  final AdConfig _config;
  final AdPolicy _policy;
  final bool isSupportedPlatform;

  bool get _isSupportedPlatform => isSupportedPlatform;

  AdConsentStatus _consentStatus = AdConsentStatus.unknown;
  bool _canRequestAds = false;
  bool _sdkInitialized = false;

  @override
  AdConfig get config => _config;

  @override
  AdPolicy get policy => _policy;

  @override
  AdConsentStatus get consentStatus => _consentStatus;

  @override
  bool get canRequestAds => _canRequestAds;

  @override
  void notifyFirstSoundReached() {
    _policy.recordFirstSound();
  }

  @override
  Future<AdConsentStatus> runConsentFlowIfRequired() async {
    if (!_isSupportedPlatform || kIsWeb) {
      _consentStatus = AdConsentStatus.notRequired;
      _canRequestAds = false;
      return _consentStatus;
    }

    final Completer<AdConsentStatus> completer = Completer<AdConsentStatus>();
    try {
      final ConsentRequestParameters params = ConsentRequestParameters();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          ConsentForm.loadAndShowConsentFormIfRequired((
            FormError? formError,
          ) async {
            final ConsentStatus status = await ConsentInformation.instance
                .getConsentStatus();
            final bool allowed = await ConsentInformation.instance
                .canRequestAds();
            _canRequestAds = allowed;
            _consentStatus = switch (status) {
              ConsentStatus.notRequired => AdConsentStatus.notRequired,
              ConsentStatus.obtained => AdConsentStatus.obtained,
              ConsentStatus.required => AdConsentStatus.required,
              ConsentStatus.unknown => AdConsentStatus.unknown,
            };
            if (_canRequestAds && !_sdkInitialized) {
              await MobileAds.instance.initialize();
              _sdkInitialized = true;
            }
            if (!completer.isCompleted) {
              completer.complete(_consentStatus);
            }
          });
        },
        (FormError error) async {
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
          if (_canRequestAds && !_sdkInitialized) {
            await MobileAds.instance.initialize();
            _sdkInitialized = true;
          }
          if (!completer.isCompleted) {
            completer.complete(_consentStatus);
          }
        },
      );
    } catch (_) {
      _consentStatus = AdConsentStatus.notRequired;
      if (!completer.isCompleted) {
        completer.complete(_consentStatus);
      }
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => _consentStatus,
    );
  }

  @override
  Future<bool> showInterstitialIfEligible({
    required Entitlement entitlement,
    required String route,
    required AdBreakTrigger trigger,
  }) async {
    if (!_policy.canShowInterstitial(
      entitlement: entitlement,
      route: route,
      trigger: trigger,
    )) {
      return false;
    }

    final String? unitId = _config.interstitialAdUnitId;
    if (unitId == null || !_canRequestAds || !_isSupportedPlatform) {
      return false;
    }

    final Completer<bool> completer = Completer<bool>();
    try {
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent:
                  (InterstitialAd ad, AdError err) {
                    ad.dispose();
                  },
            );
            _policy.recordInterstitialShown();
            ad.show();
            if (!completer.isCompleted) {
              completer.complete(true);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (!completer.isCompleted) {
              completer.complete(false);
            }
          },
        ),
      );
    } catch (_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }
    return completer.future;
  }

  @override
  Future<Result<Entitlement>> showRewardedAdForPlusPass({
    required EntitlementRepository entitlementRepository,
  }) async {
    final Result<Entitlement> currentRes = await entitlementRepository
        .getEntitlement();
    final Entitlement current = switch (currentRes) {
      Success<Entitlement>(:final data) => data,
      Failure<Entitlement>() => const Entitlement(),
    };

    if (!_policy.canOfferRewardedAd(entitlement: current)) {
      return Success<Entitlement>(current);
    }

    final String? unitId = _config.rewardedAdUnitId;
    if (unitId == null || !_canRequestAds || !_isSupportedPlatform) {
      return const Failure<Entitlement>(
        AppFailure.network(
          message: 'Rewarded ad is not available right now. Please try again.',
        ),
      );
    }

    final Completer<Result<Entitlement>> completer =
        Completer<Result<Entitlement>>();
    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            bool earnedReward = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (RewardedAd ad) async {
                ad.dispose();
                if (!earnedReward && !completer.isCompleted) {
                  completer.complete(
                    const Failure<Entitlement>(
                      AppFailure.validation(
                        message:
                            'Watch the full ad to unlock 24 hours of Plus features.',
                      ),
                    ),
                  );
                }
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError err) {
                ad.dispose();
                if (!completer.isCompleted) {
                  completer.complete(
                    Failure<Entitlement>(
                      AppFailure.network(message: err.message),
                    ),
                  );
                }
              },
            );
            ad.show(
              onUserEarnedReward:
                  (AdWithoutView view, RewardItem rewardItem) async {
                    earnedReward = true;
                    final Result<Entitlement> granted =
                        await entitlementRepository.grantTemporaryRewardedPass(
                          duration: AdPolicy.rewardedPassDuration,
                        );
                    if (!completer.isCompleted) {
                      completer.complete(granted);
                    }
                  },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (!completer.isCompleted) {
              completer.complete(
                Failure<Entitlement>(
                  AppFailure.network(
                    message: 'Could not load rewarded ad: ${error.message}',
                  ),
                ),
              );
            }
          },
        ),
      );
    } catch (error) {
      if (!completer.isCompleted) {
        completer.complete(
          Failure<Entitlement>(
            AppFailure.network(message: 'Failed to show rewarded ad: $error'),
          ),
        );
      }
    }
    return completer.future;
  }
}
