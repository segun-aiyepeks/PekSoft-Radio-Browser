import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import type {
  RawRadioBrowserCountry,
  RawRadioBrowserLanguage,
  RawRadioBrowserStation,
  RawRadioBrowserTag,
} from '@peksoft/shared';
import { describe, expect, it } from 'vitest';
import { InMemoryLruCache } from './cache/in-memory-lru-cache.js';
import type { Env } from './config/env.js';
import {
  RadioBrowserClient,
  type HttpTransport,
} from './repositories/radio-browser-client.js';
import { buildServer } from './server.js';

const here = dirname(fileURLToPath(import.meta.url));
const fixtureDir = resolve(here, '../../../packages/shared/fixtures/radio-browser');

function readFixture<T>(filename: string): T {
  return JSON.parse(readFileSync(resolve(fixtureDir, filename), 'utf8')) as T;
}

const serversFixture = readFixture<Array<{ name: string }>>('servers.json');
const countriesFixture = readFixture<RawRadioBrowserCountry[]>('countries.json');
const tagsFixture = readFixture<RawRadioBrowserTag[]>('tags.json');
const languagesFixture = readFixture<RawRadioBrowserLanguage[]>('languages.json');
const topClickFixture = readFixture<RawRadioBrowserStation[]>(
  'stations-topclick.json',
);
const ngWorkingFixture = readFixture<RawRadioBrowserStation[]>(
  'stations-ng-working.json',
);

class FixtureTransport implements HttpTransport {
  readonly requestedUrls: string[] = [];

  async getJson<T>(url: string, headers: Record<string, string>): Promise<T> {
    this.requestedUrls.push(url);
    expect(headers['User-Agent']).toMatch(/^PekSoftRadioBrowser\//);

    if (url.endsWith('/json/servers')) {
      return serversFixture as unknown as T;
    }
    if (url.includes('/json/countries')) {
      return countriesFixture as unknown as T;
    }
    if (url.includes('/json/tags')) {
      return tagsFixture as unknown as T;
    }
    if (url.includes('/json/languages')) {
      return languagesFixture as unknown as T;
    }
    if (url.includes('/json/stations/byuuid/')) {
      const uuid = decodeURIComponent(url.split('/json/stations/byuuid/')[1] ?? '');
      const match = topClickFixture.find((s) => s.stationuuid === uuid);
      return (match ? [match] : []) as unknown as T;
    }
    if (url.includes('/json/stations/search')) {
      if (url.includes('countrycode=NG')) {
        return ngWorkingFixture as unknown as T;
      }
      return topClickFixture as unknown as T;
    }
    throw new Error(`Unexpected fixture URL: ${url}`);
  }
}

function makeTestEnv(): Env {
  return {
    PORT: 4000,
    HOST: '0.0.0.0',
    NODE_ENV: 'test',
    LOG_LEVEL: 'silent',
    CORS_ORIGINS: '*',
    RATE_LIMIT_MAX: 100,
    RATE_LIMIT_WINDOW_MS: 60_000,
    APP_VERSION: '0.1.0',
  };
}

describe('Milestone 4.2 Radio Browser gateway', () => {
  it('InMemoryLruCache enforces LRU eviction and TTL expiry', async () => {
    let now = 1000;
    const cache = new InMemoryLruCache({ maxEntries: 2, now: () => now });

    await cache.set('a', 1, 500);
    await cache.set('b', 2, 500);
    // Touch 'a' so 'b' becomes least-recently-used
    expect(await cache.get<number>('a')).toBe(1);

    await cache.set('c', 3, 500);
    expect(await cache.get<number>('b')).toBeNull();
    expect(await cache.get<number>('a')).toBe(1);
    expect(await cache.get<number>('c')).toBe(3);

    now += 600;
    expect(await cache.get<number>('a')).toBeNull();
  });

  it('RadioBrowserClient fails over to the next mirror when the first fails', async () => {
    const cache = new InMemoryLruCache();
    await cache.set('rb:mirrors:v1', ['bad.example.com', 'good.example.com'], 60_000);

    const attempted: string[] = [];
    const client = new RadioBrowserClient({
      appVersion: '0.1.0',
      cache,
      random: () => 0,
      transport: {
        async getJson<T>(url: string): Promise<T> {
          attempted.push(url);
          if (url.startsWith('https://bad.example.com')) {
            throw new Error('503 from bad mirror');
          }
          return countriesFixture.slice(0, 2) as unknown as T;
        },
      },
    });

    const countries = await client.getCountries();
    expect(countries).toHaveLength(2);
    expect(attempted).toEqual([
      'https://bad.example.com/json/countries?order=stationcount&reverse=true&hidebroken=true',
      'https://good.example.com/json/countries?order=stationcount&reverse=true&hidebroken=true',
    ]);
  });

  it('serves catalog endpoints with genre normalisation, LRU caching, and Cache-Control', async () => {
    const transport = new FixtureTransport();
    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      radioBrowserTransport: transport,
    });

    const countriesRes = await app.inject({
      method: 'GET',
      url: '/v1/catalog/countries',
    });
    expect(countriesRes.statusCode).toBe(200);
    expect(countriesRes.headers['cache-control']).toContain('max-age=3600');
    expect(countriesRes.json().items.length).toBeGreaterThan(100);

    const genresRes = await app.inject({
      method: 'GET',
      url: '/v1/catalog/genres',
    });
    expect(genresRes.statusCode).toBe(200);
    expect(genresRes.headers['cache-control']).toContain('max-age=3600');
    const genres = genresRes.json().items as Array<{ id: string; stationCount: number }>;
    expect(genres.some((g) => g.id === 'pop' && g.stationCount > 0)).toBe(true);

    const languagesRes = await app.inject({
      method: 'GET',
      url: '/v1/catalog/languages',
    });
    expect(languagesRes.statusCode).toBe(200);
    expect(languagesRes.json().items.length).toBeGreaterThan(50);

    // Second call hits cache without issuing another upstream transport call
    const callsBefore = transport.requestedUrls.length;
    await app.inject({ method: 'GET', url: '/v1/catalog/countries' });
    expect(transport.requestedUrls.length).toBe(callsBefore);

    await app.close();
  });

  it('serves trending, search (with httpsOnly & workingOnly), and station detail', async () => {
    const transport = new FixtureTransport();
    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      radioBrowserTransport: transport,
    });

    const trendingRes = await app.inject({
      method: 'GET',
      url: '/v1/stations/trending?limit=10',
    });
    expect(trendingRes.statusCode).toBe(200);
    expect(trendingRes.headers['cache-control']).toContain('max-age=120');
    expect(trendingRes.json().items).toHaveLength(10);

    const searchHttps = await app.inject({
      method: 'GET',
      url: '/v1/stations/search?country=NG&httpsOnly=true&limit=20',
    });
    expect(searchHttps.statusCode).toBe(200);
    expect(searchHttps.headers['cache-control']).toContain('max-age=60');
    const items = searchHttps.json().items as Array<{
      isWorking: boolean;
      isHttpsPlayable: boolean;
      countryCode: string;
    }>;
    expect(items.length).toBeGreaterThan(0);
    expect(items.every((s) => s.isWorking && s.isHttpsPlayable && s.countryCode === 'NG')).toBe(
      true,
    );

    const firstId = topClickFixture[0]!.stationuuid;
    const detailRes = await app.inject({
      method: 'GET',
      url: `/v1/stations/${firstId}`,
    });
    expect(detailRes.statusCode).toBe(200);
    expect(detailRes.headers['cache-control']).toContain('max-age=300');
    expect(detailRes.json().station.id).toBe(firstId);

    const missingRes = await app.inject({
      method: 'GET',
      url: '/v1/stations/00000000-0000-0000-0000-000000000000',
    });
    expect(missingRes.statusCode).toBe(404);
    expect(missingRes.json().error.code).toBe('NOT_FOUND');

    await app.close();
  });
});
