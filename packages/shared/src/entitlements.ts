import { z } from 'zod';

export const entitlementTierSchema = z.enum(['FREE', 'PLUS']);
export type EntitlementTier = z.infer<typeof entitlementTierSchema>;

export const entitlementStatusSchema = z.enum([
  'ACTIVE',
  'GRACE',
  'EXPIRED',
  'CANCELLED',
]);
export type EntitlementStatus = z.infer<typeof entitlementStatusSchema>;

export const entitlementSourceSchema = z.enum([
  'NONE',
  'GOOGLE_PLAY',
  'PAYSTACK',
  'PROMO',
]);
export type EntitlementSource = z.infer<typeof entitlementSourceSchema>;

export const paymentProviderSourceSchema = z.enum(['google_play', 'paystack']);
export type PaymentProviderSource = z.infer<typeof paymentProviderSourceSchema>;

export const sleepTimerModeSchema = z.enum(['presets', 'custom_and_fade_out']);
export type SleepTimerMode = z.infer<typeof sleepTimerModeSchema>;

export const themesAndWidgetsModeSchema = z.enum(['basic', 'all']);
export type ThemesAndWidgetsMode = z.infer<typeof themesAndWidgetsModeSchema>;

export const planFeatureGateSchema = z.object({
  tier: entitlementTierSchema,
  browseAndPlayWorldwide: z.boolean(),
  basicSearchAndFilters: z.boolean(),
  adsEnabled: z.boolean(),
  maxFavorites: z.number().int().positive().nullable(),
  maxCollections: z.number().int().positive().nullable(),
  maxRecentlyPlayed: z.number().int().positive(),
  maxSongHistory: z.number().int().positive().nullable(),
  sleepTimerMode: sleepTimerModeSchema,
  customSleepTimer: z.boolean(),
  sleepTimerFadeOut: z.boolean(),
  alarmClock: z.boolean(),
  equalizerAndBassBoost: z.boolean(),
  advancedFilters: z.boolean(),
  themesAndWidgets: themesAndWidgetsModeSchema,
  allThemesAndWidgets: z.boolean(),
  crossDeviceSync: z.boolean(),
  earlyAccessAndPrioritySupport: z.boolean(),
});

export type PlanFeatureGate = z.infer<typeof planFeatureGateSchema>;

export const featureGateTableSchema = z.object({
  version: z.number().int().positive(),
  source: z.string().min(1),
  plans: z.object({
    FREE: planFeatureGateSchema,
    PLUS: planFeatureGateSchema,
  }),
});

export type FeatureGateTable = z.infer<typeof featureGateTableSchema>;

/**
 * Canonical Free vs Plus feature-gate table from Section 7 of docs/ux-document.md,
 * shared across apps/api, apps/web, and apps/mobile (via feature-gates.json).
 */
export const FEATURE_GATE_TABLE: FeatureGateTable = {
  version: 1,
  source: 'docs/ux-document.md#section-7',
  plans: {
    FREE: {
      tier: 'FREE',
      browseAndPlayWorldwide: true,
      basicSearchAndFilters: true,
      adsEnabled: true,
      maxFavorites: 30,
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
    },
    PLUS: {
      tier: 'PLUS',
      browseAndPlayWorldwide: true,
      basicSearchAndFilters: true,
      adsEnabled: false,
      maxFavorites: null,
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
    },
  },
};

export const PLAN_FEATURE_GATES: Record<EntitlementTier, PlanFeatureGate> =
  FEATURE_GATE_TABLE.plans;

export function getPlanFeatureGate(tier: EntitlementTier): PlanFeatureGate {
  return PLAN_FEATURE_GATES[tier];
}

export function toPrismaEntitlementSource(
  source: PaymentProviderSource,
): 'GOOGLE_PLAY' | 'PAYSTACK' {
  return source === 'google_play' ? 'GOOGLE_PLAY' : 'PAYSTACK';
}

export function fromPrismaEntitlementSource(
  source: EntitlementSource,
): 'none' | 'promo' | PaymentProviderSource {
  switch (source) {
    case 'GOOGLE_PLAY':
      return 'google_play';
    case 'PAYSTACK':
      return 'paystack';
    case 'PROMO':
      return 'promo';
    case 'NONE':
      return 'none';
  }
}
