import { describe, expect, it } from 'vitest';
import { isAdBlockedRoute, shouldRenderWebAds } from './ad-policy';

describe('ad-policy', () => {
  it('blocks ads on auth, pricing, and checkout routes', () => {
    expect(isAdBlockedRoute('/auth')).toBe(true);
    expect(isAdBlockedRoute('/pricing')).toBe(true);
    expect(isAdBlockedRoute('/checkout')).toBe(true);
    expect(isAdBlockedRoute('/checkout/callback')).toBe(true);
    expect(isAdBlockedRoute('/home')).toBe(false);
    expect(isAdBlockedRoute('/explore')).toBe(false);
    expect(isAdBlockedRoute('/station/cool-fm')).toBe(false);
  });

  it('hides all ads for Plus users regardless of consent or route', () => {
    expect(
      shouldRenderWebAds({
        isPlus: true,
        consentStatus: 'granted',
        pathname: '/home',
      }),
    ).toBe(false);
  });

  it('requires explicit granted consent and non-blocked route for Free users', () => {
    expect(
      shouldRenderWebAds({
        isPlus: false,
        consentStatus: 'unknown',
        pathname: '/home',
      }),
    ).toBe(false);

    expect(
      shouldRenderWebAds({
        isPlus: false,
        consentStatus: 'denied',
        pathname: '/home',
      }),
    ).toBe(false);

    expect(
      shouldRenderWebAds({
        isPlus: false,
        consentStatus: 'granted',
        pathname: '/pricing',
      }),
    ).toBe(false);

    expect(
      shouldRenderWebAds({
        isPlus: false,
        consentStatus: 'granted',
        pathname: '/home',
      }),
    ).toBe(true);
  });
});
