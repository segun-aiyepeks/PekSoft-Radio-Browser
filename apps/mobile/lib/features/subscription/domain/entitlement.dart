import 'package:freezed_annotation/freezed_annotation.dart';

part 'entitlement.freezed.dart';

/// Subscription tier. Free by default; Pro is verified server-side.
enum EntitlementTier { free, pro }

/// Immutable user entitlement model.
@freezed
abstract class Entitlement with _$Entitlement {
  const factory Entitlement({
    @Default(EntitlementTier.free) EntitlementTier tier,
    @Default(10) int maxFavourites,
    @Default(2) int maxCollections,
    @Default(10) int maxSongHistory,
    @Default(true) bool adsEnabled,
    DateTime? expiresAt,
  }) = _Entitlement;
}
