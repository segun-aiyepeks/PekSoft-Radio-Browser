import 'package:freezed_annotation/freezed_annotation.dart';

part 'entitlement.freezed.dart';

/// Subscription tier. Free by default; Plus (`pro`) is verified server-side.
enum EntitlementTier {
  free,
  pro;

  static const EntitlementTier plus = EntitlementTier.pro;

  bool get isPlus => this == EntitlementTier.pro;
}

/// Lifecycle status of a subscription entitlement.
enum EntitlementStatus { active, grace, expired, cancelled }

/// Provider that granted or last modified the entitlement.
enum EntitlementSource { none, googlePlay, paystack, promo, rewardedAd }

/// Immutable user entitlement model backed by the shared Section 7 feature-gate table.
@freezed
abstract class Entitlement with _$Entitlement {
  const factory Entitlement({
    @Default(EntitlementTier.free) EntitlementTier tier,
    @Default(EntitlementStatus.active) EntitlementStatus status,
    @Default(EntitlementSource.none) EntitlementSource source,
    @Default(30) int maxFavourites,
    @Default(2) int maxCollections,
    @Default(20) int maxRecentlyPlayed,
    @Default(10) int maxSongHistory,
    @Default(true) bool adsEnabled,
    DateTime? expiresAt,
    DateTime? rewardedPlusExpiresAt,
  }) = _Entitlement;
}

extension EntitlementLifecycleX on Entitlement {
  /// True when the user has an active or grace-period paid Plus subscription.
  bool isPaidPlusActiveAt([DateTime? clock]) {
    final DateTime now = clock ?? DateTime.now();
    if (tier != EntitlementTier.pro) return false;
    if (status != EntitlementStatus.active &&
        status != EntitlementStatus.grace) {
      return false;
    }
    if (expiresAt != null && !expiresAt!.isAfter(now)) {
      return false;
    }
    return true;
  }

  /// True when a 24-hour rewarded-ad convenience pass is currently active.
  bool isRewardedPassActiveAt([DateTime? clock]) {
    final DateTime now = clock ?? DateTime.now();
    return rewardedPlusExpiresAt != null && rewardedPlusExpiresAt!.isAfter(now);
  }

  /// True when either paid Plus or a temporary rewarded-ad pass is active.
  bool isPlusActiveAt([DateTime? clock]) {
    return isPaidPlusActiveAt(clock) || isRewardedPassActiveAt(clock);
  }
}
