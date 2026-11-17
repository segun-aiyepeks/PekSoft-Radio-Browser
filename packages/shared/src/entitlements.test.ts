import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import {
  FEATURE_GATE_TABLE,
  PLAN_FEATURE_GATES,
  featureGateTableSchema,
  fromPrismaEntitlementSource,
  getPlanFeatureGate,
  toPrismaEntitlementSource,
} from './entitlements.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

describe('shared entitlement feature gates (UX document section 7)', () => {
  it('matches packages/shared/feature-gates.json exactly', () => {
    const raw = JSON.parse(
      readFileSync(resolve(__dirname, '../feature-gates.json'), 'utf8'),
    );
    const parsed = featureGateTableSchema.parse(raw);
    expect(parsed).toEqual(FEATURE_GATE_TABLE);
  });

  it('defines FREE and PLUS rules from section 7 of docs/ux-document.md', () => {
    const free = getPlanFeatureGate('FREE');
    const plus = getPlanFeatureGate('PLUS');

    expect(free.browseAndPlayWorldwide).toBe(true);
    expect(plus.browseAndPlayWorldwide).toBe(true);

    expect(free.basicSearchAndFilters).toBe(true);
    expect(plus.basicSearchAndFilters).toBe(true);

    expect(free.adsEnabled).toBe(true);
    expect(plus.adsEnabled).toBe(false);

    expect(free.maxFavorites).toBe(30);
    expect(plus.maxFavorites).toBeNull();

    expect(free.maxCollections).toBe(2);
    expect(plus.maxCollections).toBeNull();

    expect(free.maxRecentlyPlayed).toBe(20);
    expect(plus.maxRecentlyPlayed).toBe(200);

    expect(free.maxSongHistory).toBe(10);
    expect(plus.maxSongHistory).toBeNull();

    expect(free.sleepTimerMode).toBe('presets');
    expect(free.customSleepTimer).toBe(false);
    expect(free.sleepTimerFadeOut).toBe(false);

    expect(plus.sleepTimerMode).toBe('custom_and_fade_out');
    expect(plus.customSleepTimer).toBe(true);
    expect(plus.sleepTimerFadeOut).toBe(true);

    expect(free.alarmClock).toBe(false);
    expect(plus.alarmClock).toBe(true);

    expect(free.equalizerAndBassBoost).toBe(false);
    expect(plus.equalizerAndBassBoost).toBe(true);

    expect(free.advancedFilters).toBe(false);
    expect(plus.advancedFilters).toBe(true);

    expect(free.themesAndWidgets).toBe('basic');
    expect(free.allThemesAndWidgets).toBe(false);
    expect(plus.themesAndWidgets).toBe('all');
    expect(plus.allThemesAndWidgets).toBe(true);

    expect(free.crossDeviceSync).toBe(true);
    expect(plus.crossDeviceSync).toBe(true);

    expect(free.earlyAccessAndPrioritySupport).toBe(false);
    expect(plus.earlyAccessAndPrioritySupport).toBe(true);
    expect(PLAN_FEATURE_GATES.FREE).toEqual(free);
    expect(PLAN_FEATURE_GATES.PLUS).toEqual(plus);
  });

  it('converts payment provider source identifiers cleanly', () => {
    expect(toPrismaEntitlementSource('google_play')).toBe('GOOGLE_PLAY');
    expect(toPrismaEntitlementSource('paystack')).toBe('PAYSTACK');
    expect(fromPrismaEntitlementSource('GOOGLE_PLAY')).toBe('google_play');
    expect(fromPrismaEntitlementSource('PAYSTACK')).toBe('paystack');
    expect(fromPrismaEntitlementSource('NONE')).toBe('none');
  });
});
