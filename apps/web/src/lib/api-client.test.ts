import { describe, expect, it } from 'vitest';
import type { StationDto } from '@peksoft/shared';
import {
  countryCodeToFlag,
  slugifyStationName,
  stationDtoToWebStation,
} from './api-client';
import { buildMetadata, buildStationJsonLd } from './seo';

describe('api-client mapping', () => {
  it('converts ISO-2 country codes to emoji flags', () => {
    expect(countryCodeToFlag('NG')).toBe('🇳🇬');
    expect(countryCodeToFlag('gb')).toBe('🇬🇧');
    expect(countryCodeToFlag('invalid')).toBe('🌍');
  });

  it('builds deterministic station slugs', () => {
    expect(slugifyStationName('Cool FM 96.9 Lagos', '12345678-abcd')).toBe(
      'cool-fm-96-9-lagos--12345678-abcd',
    );
  });

  it('maps StationDto from @peksoft/shared to WebStation', () => {
    const dto: StationDto = {
      id: 'st-12345678-uuid',
      name: 'Wazobia FM 95.1',
      streamUrl: 'https://stream.example.com/live.mp3',
      fallbackStreamUrl: 'https://backup.example.com/live.mp3',
      homepage: 'https://wazobiafm.com',
      faviconUrl: undefined,
      usesFallbackLogo: true,
      isHttps: true,
      isHttpsPlayable: true,
      isHls: false,
      isWorking: true,
      countryCode: 'NG',
      countryName: 'Nigeria',
      genres: [{ id: 'afrobeats', name: 'Afrobeats & Pop', stationCount: 10 }],
      language: 'Pidgin',
      codec: 'AAC',
      bitrateKbps: 128,
      votes: 420,
      clickCount: 9000,
      clickTrend: 12,
    };

    const web = stationDtoToWebStation(dto);
    expect(web.countryFlag).toBe('🇳🇬');
    expect(web.fallbackStreamUrl).toBe('https://backup.example.com/live.mp3');
    expect(web.genres).toEqual(['afrobeats']);
    expect(web.isHttpsPlayable).toBe(true);
    expect(web.slug).toBe('wazobia-fm-95-1--st-12345678-uuid');
  });
});

describe('seo helpers', () => {
  it('builds metadata with canonical path and OG image', () => {
    const meta = buildMetadata({
      title: 'Explore',
      description: 'Browse stations',
      path: '/explore',
    });
    expect(meta.alternates?.canonical).toBe('/explore');
    expect(meta.openGraph?.url).toBe('/explore');
  });

  it('builds RadioStation JSON-LD', () => {
    const jsonLd = buildStationJsonLd({
      id: 'st-1',
      slug: 'cool-fm-1',
      name: 'Cool FM',
      streamUrl: 'https://coolfm.ng/live.mp3',
      homepage: 'https://coolfm.ng',
      faviconUrl: null,
      isHttps: true,
      isHttpsPlayable: true,
      isHls: false,
      isWorking: true,
      countryCode: 'NG',
      countryName: 'Nigeria',
      countryFlag: '🇳🇬',
      genres: ['afrobeats'],
      language: 'English',
      codec: 'MP3',
      bitrateKbps: 128,
      votes: 100,
      clickCount: 1000,
    });
    expect(jsonLd['@type']).toBe('RadioStation');
    expect(jsonLd.name).toBe('Cool FM');
    expect(jsonLd.areaServed).toBe('Nigeria');
  });
});
