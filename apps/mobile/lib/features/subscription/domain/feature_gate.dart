import 'package:flutter/foundation.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

/// Immutable plan feature-gate definition from Section 7 of `docs/ux-document.md`
/// (`packages/shared/feature-gates.json`).
@immutable
class PlanFeatureGates {
  const PlanFeatureGates({
    required this.tier,
    required this.browseAndPlayWorldwide,
    required this.basicSearchAndFilters,
    required this.adsEnabled,
    required this.maxFavourites,
    required this.maxCollections,
    required this.maxRecentlyPlayed,
    required this.maxSongHistory,
    required this.sleepTimerMode,
    required this.customSleepTimer,
    required this.sleepTimerFadeOut,
    required this.alarmClock,
    required this.equalizerAndBassBoost,
    required this.advancedFilters,
    required this.themesAndWidgets,
    required this.allThemesAndWidgets,
    required this.crossDeviceSync,
    required this.earlyAccessAndPrioritySupport,
  });

  factory PlanFeatureGates.fromJson(Map<String, dynamic> json) {
    return PlanFeatureGates(
      tier: json['tier'] as String,
      browseAndPlayWorldwide: json['browseAndPlayWorldwide'] as bool,
      basicSearchAndFilters: json['basicSearchAndFilters'] as bool,
      adsEnabled: json['adsEnabled'] as bool,
      maxFavourites: json['maxFavorites'] as int?,
      maxCollections: json['maxCollections'] as int?,
      maxRecentlyPlayed: json['maxRecentlyPlayed'] as int,
      maxSongHistory: json['maxSongHistory'] as int?,
      sleepTimerMode: json['sleepTimerMode'] as String,
      customSleepTimer: json['customSleepTimer'] as bool,
      sleepTimerFadeOut: json['sleepTimerFadeOut'] as bool,
      alarmClock: json['alarmClock'] as bool,
      equalizerAndBassBoost: json['equalizerAndBassBoost'] as bool,
      advancedFilters: json['advancedFilters'] as bool,
      themesAndWidgets: json['themesAndWidgets'] as String,
      allThemesAndWidgets: json['allThemesAndWidgets'] as bool,
      crossDeviceSync: json['crossDeviceSync'] as bool,
      earlyAccessAndPrioritySupport:
          json['earlyAccessAndPrioritySupport'] as bool,
    );
  }

  final String tier;
  final bool browseAndPlayWorldwide;
  final bool basicSearchAndFilters;
  final bool adsEnabled;
  final int? maxFavourites;
  final int? maxCollections;
  final int maxRecentlyPlayed;
  final int? maxSongHistory;
  final String sleepTimerMode;
  final bool customSleepTimer;
  final bool sleepTimerFadeOut;
  final bool alarmClock;
  final bool equalizerAndBassBoost;
  final bool advancedFilters;
  final String themesAndWidgets;
  final bool allThemesAndWidgets;
  final bool crossDeviceSync;
  final bool earlyAccessAndPrioritySupport;

  /// Canonical Free tier gates from `packages/shared/feature-gates.json`.
  static const PlanFeatureGates free = PlanFeatureGates(
    tier: 'FREE',
    browseAndPlayWorldwide: true,
    basicSearchAndFilters: true,
    adsEnabled: true,
    maxFavourites: 30,
    maxCollections: 2,
    maxRecentlyPlayed: 20,
    maxSongHistory: 10,
    sleepTimerMode: 'presets',
    customSleepTimer: false,
    sleepTimerFadeOut: false,
    alarmClock: false,
    equalizerAndBassBoost: false,
    advancedFilters: false,
    themesAndWidgets: 'basic',
    allThemesAndWidgets: false,
    crossDeviceSync: true,
    earlyAccessAndPrioritySupport: false,
  );

  /// Canonical Plus tier gates from `packages/shared/feature-gates.json`.
  static const PlanFeatureGates plus = PlanFeatureGates(
    tier: 'PLUS',
    browseAndPlayWorldwide: true,
    basicSearchAndFilters: true,
    adsEnabled: false,
    maxFavourites: null,
    maxCollections: null,
    maxRecentlyPlayed: 200,
    maxSongHistory: null,
    sleepTimerMode: 'custom_and_fade_out',
    customSleepTimer: true,
    sleepTimerFadeOut: true,
    alarmClock: true,
    equalizerAndBassBoost: true,
    advancedFilters: true,
    themesAndWidgets: 'all',
    allThemesAndWidgets: true,
    crossDeviceSync: true,
    earlyAccessAndPrioritySupport: true,
  );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlanFeatureGates &&
            other.tier == tier &&
            other.browseAndPlayWorldwide == browseAndPlayWorldwide &&
            other.basicSearchAndFilters == basicSearchAndFilters &&
            other.adsEnabled == adsEnabled &&
            other.maxFavourites == maxFavourites &&
            other.maxCollections == maxCollections &&
            other.maxRecentlyPlayed == maxRecentlyPlayed &&
            other.maxSongHistory == maxSongHistory &&
            other.sleepTimerMode == sleepTimerMode &&
            other.customSleepTimer == customSleepTimer &&
            other.sleepTimerFadeOut == sleepTimerFadeOut &&
            other.alarmClock == alarmClock &&
            other.equalizerAndBassBoost == equalizerAndBassBoost &&
            other.advancedFilters == advancedFilters &&
            other.themesAndWidgets == themesAndWidgets &&
            other.allThemesAndWidgets == allThemesAndWidgets &&
            other.crossDeviceSync == crossDeviceSync &&
            other.earlyAccessAndPrioritySupport ==
                earlyAccessAndPrioritySupport);
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    tier,
    browseAndPlayWorldwide,
    basicSearchAndFilters,
    adsEnabled,
    maxFavourites,
    maxCollections,
    maxRecentlyPlayed,
    maxSongHistory,
    sleepTimerMode,
    customSleepTimer,
    sleepTimerFadeOut,
    alarmClock,
    equalizerAndBassBoost,
    advancedFilters,
    themesAndWidgets,
    allThemesAndWidgets,
    crossDeviceSync,
    earlyAccessAndPrioritySupport,
  ]);
}

/// Single feature-gate authority used across every ViewModel and Repository on
/// mobile, backed by the shared Section 7 feature-gate table.
@immutable
class FeatureGate {
  const FeatureGate(this.entitlement, {this.now});

  final Entitlement entitlement;
  final DateTime? now;

  /// True when the user has an active or grace-period server-verified Plus
  /// subscription, or an active 24-hour rewarded-ad convenience pass.
  bool get isPlus => entitlement.isPlusActiveAt(now);

  /// True only when the user has a server-verified paid Plus subscription
  /// (as opposed to a temporary rewarded-ad convenience pass).
  bool get isPaidPlus => entitlement.isPaidPlusActiveAt(now);

  /// Active plan rules from Section 7 of `docs/ux-document.md`.
  PlanFeatureGates get plan =>
      isPlus ? PlanFeatureGates.plus : PlanFeatureGates.free;

  bool get browseAndPlayWorldwide => plan.browseAndPlayWorldwide;

  bool get basicSearchAndFilters => plan.basicSearchAndFilters;

  /// Ads are disabled for paid Plus subscribers and while a rewarded pass is active.
  bool get adsEnabled => plan.adsEnabled;

  /// Maximum favourites (`30` on Free, `null` = unlimited on Plus).
  int? get maxFavourites =>
      isPlus ? PlanFeatureGates.plus.maxFavourites : entitlement.maxFavourites;

  /// Maximum custom collections (`2` on Free, `null` = unlimited on Plus).
  int? get maxCollections => isPlus
      ? PlanFeatureGates.plus.maxCollections
      : entitlement.maxCollections;

  /// Maximum recently played stations (`20` on Free, `200` on Plus).
  int get maxRecentlyPlayed => isPlus
      ? PlanFeatureGates.plus.maxRecentlyPlayed
      : entitlement.maxRecentlyPlayed;

  /// Maximum song history entries (`10` on Free, `null` = unlimited on Plus).
  int? get maxSongHistory => isPlus
      ? PlanFeatureGates.plus.maxSongHistory
      : entitlement.maxSongHistory;

  bool canAddFavourite(int currentCount) {
    final int? limit = maxFavourites;
    return limit == null || currentCount < limit;
  }

  bool canCreateCollection(int currentCustomCount) {
    final int? limit = maxCollections;
    return limit == null || currentCustomCount < limit;
  }

  bool get canUseCustomSleepTimer => plan.customSleepTimer;

  bool get canUseSleepTimerFadeOut => plan.sleepTimerFadeOut;

  bool get canUseAdvancedFilters => plan.advancedFilters;

  bool get canUseAlarmClock => plan.alarmClock;

  bool get canUseEqualizer => plan.equalizerAndBassBoost;

  bool get canUseAllThemesAndWidgets => plan.allThemesAndWidgets;

  bool get canUseCrossDeviceSync => plan.crossDeviceSync;

  bool get hasEarlyAccessAndPrioritySupport =>
      plan.earlyAccessAndPrioritySupport;
}
