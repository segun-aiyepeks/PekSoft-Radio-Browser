import 'dart:convert';

import 'package:peksoft_radio/core/database/app_database.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/features/auth/domain/auth_repository.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement_repository.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';

/// Server-verified [EntitlementRepository] backed by `GET /v1/entitlements` and
/// cached locally in [AppDatabase] for offline launches.
class EntitlementRepositoryImpl implements EntitlementRepository {
  const EntitlementRepositoryImpl({
    this.defaultEntitlement = const Entitlement(),
    this.apiClient,
    this.authRepository,
    this.database,
    this.now,
  });

  static const String cacheKey = 'entitlement:current:v1';
  static const Duration cacheTtl = Duration(hours: 6);

  final Entitlement defaultEntitlement;
  final ApiClient? apiClient;
  final AuthRepository? authRepository;
  final AppDatabase? database;
  final DateTime Function()? now;

  Entitlement get _defaultEntitlement => defaultEntitlement;
  AppDatabase? get _database => database;
  DateTime Function()? get _now => now;

  DateTime _currentTime() => (_now ?? DateTime.now)();

  bool get _isSignedIn {
    final AuthRepository? auth = authRepository;
    if (auth == null) {
      return apiClient != null;
    }
    return auth.currentUser != null;
  }

  @override
  Future<Result<Entitlement>> getEntitlement() async {
    if (apiClient == null && database == null) {
      return Success<Entitlement>(_normalizeExpiry(_defaultEntitlement));
    }

    final Entitlement? cached = await _readCachedEntitlement();
    if (!_isSignedIn) {
      final DateTime? rewardedUntil = cached?.rewardedPlusExpiresAt;
      final bool hasActiveReward =
          rewardedUntil != null && rewardedUntil.isAfter(_currentTime());
      return Success<Entitlement>(
        _defaultEntitlement.copyWith(
          source: hasActiveReward
              ? EntitlementSource.rewardedAd
              : EntitlementSource.none,
          adsEnabled: !hasActiveReward,
          rewardedPlusExpiresAt: hasActiveReward ? rewardedUntil : null,
        ),
      );
    }

    if (cached != null) {
      return Success<Entitlement>(_normalizeExpiry(cached));
    }

    return refreshEntitlement();
  }

  @override
  Future<Result<Entitlement>> refreshEntitlement() async {
    final ApiClient? client = apiClient;
    if (client == null && database == null) {
      return Success<Entitlement>(_normalizeExpiry(_defaultEntitlement));
    }

    final Entitlement? cached = await _readCachedEntitlement();
    if (!_isSignedIn || client == null) {
      final Entitlement fallback = _normalizeExpiry(
        cached ?? _defaultEntitlement,
      );
      return Success<Entitlement>(fallback);
    }

    final Result<Map<String, dynamic>> res = await client.getJson(
      '/v1/entitlements',
    );
    switch (res) {
      case Success<Map<String, dynamic>>(:final data):
        final Entitlement parsed = _parseServerPayload(
          data,
          previousRewardedUntil: cached?.rewardedPlusExpiresAt,
        );
        await _writeCachedEntitlement(parsed);
        return Success<Entitlement>(_normalizeExpiry(parsed));
      case Failure<Map<String, dynamic>>(:final error):
        if (cached != null) {
          return Success<Entitlement>(_normalizeExpiry(cached));
        }
        return Failure<Entitlement>(error);
    }
  }

  @override
  Future<Result<Entitlement>> grantTemporaryRewardedPass({
    Duration duration = const Duration(hours: 24),
  }) async {
    final DateTime now = _currentTime();
    final DateTime rewardExpiry = now.add(duration);
    final Entitlement current = switch (await getEntitlement()) {
      Success<Entitlement>(:final data) => data,
      Failure<Entitlement>() => _defaultEntitlement,
    };

    final Entitlement updated = current.copyWith(
      source: current.isPaidPlusActiveAt(now)
          ? current.source
          : EntitlementSource.rewardedAd,
      adsEnabled: false,
      rewardedPlusExpiresAt: rewardExpiry,
    );
    await _writeCachedEntitlement(updated);
    return Success<Entitlement>(updated);
  }

  Entitlement _normalizeExpiry(Entitlement entitlement) {
    final DateTime now = _currentTime();
    final bool paidActive = entitlement.isPaidPlusActiveAt(now);
    final bool rewardActive = entitlement.isRewardedPassActiveAt(now);

    if (entitlement.tier == EntitlementTier.pro && !paidActive) {
      return entitlement.copyWith(
        tier: EntitlementTier.free,
        status: EntitlementStatus.expired,
        maxFavourites: PlanFeatureGates.free.maxFavourites ?? 30,
        maxCollections: PlanFeatureGates.free.maxCollections ?? 2,
        maxRecentlyPlayed: PlanFeatureGates.free.maxRecentlyPlayed,
        maxSongHistory: PlanFeatureGates.free.maxSongHistory ?? 10,
        adsEnabled: !rewardActive,
        rewardedPlusExpiresAt: rewardActive
            ? entitlement.rewardedPlusExpiresAt
            : null,
      );
    }

    if (!rewardActive && entitlement.rewardedPlusExpiresAt != null) {
      return entitlement.copyWith(
        adsEnabled: !paidActive,
        rewardedPlusExpiresAt: null,
      );
    }

    return entitlement;
  }

  Entitlement _parseServerPayload(
    Map<String, dynamic> payload, {
    DateTime? previousRewardedUntil,
  }) {
    final Object? rawEnt = payload['entitlement'];
    final Map<String, dynamic> entMap = rawEnt is Map<String, dynamic>
        ? rawEnt
        : payload;

    final String tierStr = (entMap['tier'] as String? ?? 'FREE').toUpperCase();
    final EntitlementTier tier = tierStr == 'PLUS' || tierStr == 'PRO'
        ? EntitlementTier.pro
        : EntitlementTier.free;

    final String statusStr = (entMap['status'] as String? ?? 'ACTIVE')
        .toUpperCase();
    final EntitlementStatus status = switch (statusStr) {
      'GRACE' => EntitlementStatus.grace,
      'EXPIRED' => EntitlementStatus.expired,
      'CANCELLED' => EntitlementStatus.cancelled,
      _ => EntitlementStatus.active,
    };

    final String sourceStr = (entMap['source'] as String? ?? 'none')
        .toLowerCase();
    final EntitlementSource source = switch (sourceStr) {
      'google_play' => EntitlementSource.googlePlay,
      'paystack' => EntitlementSource.paystack,
      'promo' => EntitlementSource.promo,
      'rewarded_ad' => EntitlementSource.rewardedAd,
      _ => EntitlementSource.none,
    };

    final Map<String, dynamic> limits =
        (entMap['limits'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};

    final int maxFavs =
        (limits['maxFavorites'] as num?)?.toInt() ??
        (tier == EntitlementTier.pro
            ? 999999
            : (PlanFeatureGates.free.maxFavourites ?? 30));
    final int maxCols =
        (limits['maxCollections'] as num?)?.toInt() ??
        (tier == EntitlementTier.pro
            ? 999999
            : (PlanFeatureGates.free.maxCollections ?? 2));
    final int maxRecents =
        (limits['maxRecentlyPlayed'] as num?)?.toInt() ??
        (tier == EntitlementTier.pro
            ? PlanFeatureGates.plus.maxRecentlyPlayed
            : PlanFeatureGates.free.maxRecentlyPlayed);
    final int maxHistory =
        (limits['maxSongHistory'] as num?)?.toInt() ??
        (tier == EntitlementTier.pro
            ? 999999
            : (PlanFeatureGates.free.maxSongHistory ?? 10));

    final String? expiresIso = entMap['expiresAt'] as String?;
    final DateTime? expiresAt = expiresIso != null
        ? DateTime.tryParse(expiresIso)
        : null;

    final DateTime now = _currentTime();
    final bool hasActiveReward =
        previousRewardedUntil != null && previousRewardedUntil.isAfter(now);
    final bool serverAdsEnabled =
        entMap['adsEnabled'] as bool? ?? (tier == EntitlementTier.free);

    return Entitlement(
      tier: tier,
      status: status,
      source: source,
      maxFavourites: maxFavs,
      maxCollections: maxCols,
      maxRecentlyPlayed: maxRecents,
      maxSongHistory: maxHistory,
      adsEnabled: serverAdsEnabled && !hasActiveReward,
      expiresAt: expiresAt,
      rewardedPlusExpiresAt: hasActiveReward ? previousRewardedUntil : null,
    );
  }

  Future<Entitlement?> _readCachedEntitlement() async {
    final AppDatabase? db = _database;
    if (db == null) return null;
    try {
      final CachedListRecord? record = await db.getCachedList(cacheKey);
      if (record == null) return null;
      final Map<String, dynamic> json =
          jsonDecode(record.payloadJson) as Map<String, dynamic>;
      final String? rewardedIso = json['rewardedPlusExpiresAt'] as String?;
      return _parseServerPayload(
        json,
        previousRewardedUntil: rewardedIso != null
            ? DateTime.tryParse(rewardedIso)
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCachedEntitlement(Entitlement entitlement) async {
    final AppDatabase? db = _database;
    if (db == null) return;
    final Map<String, dynamic> payload = <String, dynamic>{
      'tier': entitlement.tier == EntitlementTier.pro ? 'PLUS' : 'FREE',
      'status': entitlement.status.name.toUpperCase(),
      'source': switch (entitlement.source) {
        EntitlementSource.googlePlay => 'google_play',
        EntitlementSource.paystack => 'paystack',
        EntitlementSource.promo => 'promo',
        EntitlementSource.rewardedAd => 'rewarded_ad',
        EntitlementSource.none => 'none',
      },
      'adsEnabled': entitlement.adsEnabled,
      'expiresAt': entitlement.expiresAt?.toIso8601String(),
      'rewardedPlusExpiresAt': entitlement.rewardedPlusExpiresAt
          ?.toIso8601String(),
      'limits': <String, dynamic>{
        'maxFavorites': entitlement.maxFavourites,
        'maxCollections': entitlement.maxCollections,
        'maxRecentlyPlayed': entitlement.maxRecentlyPlayed,
        'maxSongHistory': entitlement.maxSongHistory,
      },
    };
    await db.saveCachedList(
      cacheKey: cacheKey,
      payloadJson: jsonEncode(payload),
      ttl: cacheTtl,
      now: _currentTime(),
    );
  }
}
