import { describe, expect, it } from 'vitest';
import { isCacheableShellRequest, shouldShowGetAppBanner } from './pwa';

describe('pwa rules', () => {
  it('never caches audio streams, range requests, or cross-origin streams', () => {
    const origin = 'https://peksoftradio.com';

    expect(
      isCacheableShellRequest({
        method: 'GET',
        url: 'https://icestream.coolfm.ng/live.mp3',
        appOrigin: origin,
        destination: 'audio',
      }),
    ).toBe(false);

    expect(
      isCacheableShellRequest({
        method: 'GET',
        url: `${origin}/stream/test.m3u8`,
        appOrigin: origin,
      }),
    ).toBe(false);

    expect(
      isCacheableShellRequest({
        method: 'GET',
        url: `${origin}/_next/static/chunks/app.js`,
        appOrigin: origin,
        hasRangeHeader: true,
      }),
    ).toBe(false);

    expect(
      isCacheableShellRequest({
        method: 'GET',
        url: `${origin}/_next/static/chunks/app.js`,
        appOrigin: origin,
      }),
    ).toBe(true);
  });

  it('shows Get the App banner only after engagement and when not dismissed or installed', () => {
    expect(
      shouldShowGetAppBanner({
        engaged: false,
        dismissed: false,
        isStandalone: false,
      }),
    ).toBe(false);

    expect(
      shouldShowGetAppBanner({
        engaged: true,
        dismissed: true,
        isStandalone: false,
      }),
    ).toBe(false);

    expect(
      shouldShowGetAppBanner({
        engaged: true,
        dismissed: false,
        isStandalone: true,
      }),
    ).toBe(false);

    expect(
      shouldShowGetAppBanner({
        engaged: true,
        dismissed: false,
        isStandalone: false,
      }),
    ).toBe(true);
  });
});
