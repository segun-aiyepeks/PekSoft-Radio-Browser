import {
  USER_AGENT_PREFIX,
  type RawRadioBrowserCountry,
  type RawRadioBrowserLanguage,
  type RawRadioBrowserStation,
  type RawRadioBrowserTag,
  type StationSearchQuery,
} from '@peksoft/shared';
import type { CacheStore } from '../cache/cache-store.js';
import { AppError } from '../errors/app-error.js';

export interface HttpTransport {
  getJson<T>(url: string, headers: Record<string, string>): Promise<T>;
}

export class FetchHttpTransport implements HttpTransport {
  constructor(private readonly timeoutMs = 8000) {}

  async getJson<T>(url: string, headers: Record<string, string>): Promise<T> {
    const response = await fetch(url, {
      method: 'GET',
      headers,
      signal: AbortSignal.timeout(this.timeoutMs),
    });
    if (!response.ok) {
      throw new Error(`Upstream HTTP ${response.status} for ${url}`);
    }
    return (await response.json()) as T;
  }
}

interface RawServerEntry {
  name?: string;
}

const MIRROR_CACHE_KEY = 'rb:mirrors:v1';
const MIRROR_TTL_MS = 24 * 60 * 60 * 1000;
const FALLBACK_MIRRORS = [
  'de1.api.radio-browser.info',
  'all.api.radio-browser.info',
];

export class RadioBrowserClient {
  private readonly userAgent: string;
  private readonly transport: HttpTransport;
  private readonly cache: CacheStore;
  private readonly random: () => number;

  constructor(options: {
    appVersion: string;
    cache: CacheStore;
    transport?: HttpTransport;
    random?: () => number;
  }) {
    this.userAgent = `${USER_AGENT_PREFIX}/${options.appVersion}`;
    this.cache = options.cache;
    this.transport = options.transport ?? new FetchHttpTransport();
    this.random = options.random ?? Math.random;
  }

  async discoverMirrors(): Promise<string[]> {
    const cached = await this.cache.get<string[]>(MIRROR_CACHE_KEY);
    if (cached && cached.length > 0) {
      return cached;
    }

    try {
      const servers = await this.transport.getJson<RawServerEntry[]>(
        'https://all.api.radio-browser.info/json/servers',
        { 'User-Agent': this.userAgent, Accept: 'application/json' },
      );
      const unique = Array.from(
        new Set(
          servers
            .map((entry) => entry.name?.trim())
            .filter((name): name is string => Boolean(name && name.length > 0)),
        ),
      );
      const mirrors = unique.length > 0 ? unique : FALLBACK_MIRRORS;
      await this.cache.set(MIRROR_CACHE_KEY, mirrors, MIRROR_TTL_MS);
      return mirrors;
    } catch {
      return FALLBACK_MIRRORS;
    }
  }

  private pickOrderedMirrors(mirrors: string[]): string[] {
    if (mirrors.length <= 1) {
      return [...mirrors];
    }
    const startIdx = Math.floor(this.random() * mirrors.length);
    return [
      ...mirrors.slice(startIdx),
      ...mirrors.slice(0, startIdx),
    ];
  }

  async fetchJson<T>(pathAndQuery: string): Promise<T> {
    const mirrors = await this.discoverMirrors();
    const ordered = this.pickOrderedMirrors(mirrors);
    const headers = {
      'User-Agent': this.userAgent,
      Accept: 'application/json',
    };

    let lastError: unknown;
    for (const host of ordered) {
      const url = `https://${host}${pathAndQuery}`;
      try {
        return await this.transport.getJson<T>(url, headers);
      } catch (err) {
        lastError = err;
      }
    }

    throw new AppError({
      statusCode: 502,
      code: 'UPSTREAM_UNAVAILABLE',
      message: 'Radio Browser mirrors are temporarily unavailable',
      details:
        lastError instanceof Error ? lastError.message : 'Unknown error',
    });
  }

  getCountries(): Promise<RawRadioBrowserCountry[]> {
    return this.fetchJson<RawRadioBrowserCountry[]>(
      '/json/countries?order=stationcount&reverse=true&hidebroken=true',
    );
  }

  getTags(limit = 500): Promise<RawRadioBrowserTag[]> {
    return this.fetchJson<RawRadioBrowserTag[]>(
      `/json/tags?order=stationcount&reverse=true&hidebroken=true&limit=${limit}`,
    );
  }

  getLanguages(limit = 200): Promise<RawRadioBrowserLanguage[]> {
    return this.fetchJson<RawRadioBrowserLanguage[]>(
      `/json/languages?order=stationcount&reverse=true&hidebroken=true&limit=${limit}`,
    );
  }

  getTrendingStations(
    limit: number,
    country?: string,
  ): Promise<RawRadioBrowserStation[]> {
    const params = new URLSearchParams({
      order: 'clickcount',
      reverse: 'true',
      hidebroken: 'true',
      limit: String(limit),
    });
    if (country) {
      params.set('countrycode', country.toUpperCase());
    }
    return this.fetchJson<RawRadioBrowserStation[]>(
      `/json/stations/search?${params.toString()}`,
    );
  }

  searchStations(
    query: StationSearchQuery,
  ): Promise<RawRadioBrowserStation[]> {
    const orderMap: Record<StationSearchQuery['sort'], string> = {
      popular: 'clickcount',
      votes: 'votes',
      recent: 'changetimestamp',
    };
    const params = new URLSearchParams({
      order: orderMap[query.sort],
      reverse: 'true',
      hidebroken: String(query.workingOnly),
      limit: String(Math.min(100, query.limit + query.offset)),
    });
    if (query.q) {
      params.set('name', query.q);
    }
    if (query.country) {
      params.set('countrycode', query.country.toUpperCase());
    }
    if (query.genre) {
      params.set('tag', query.genre.toLowerCase());
    }
    if (query.language) {
      params.set('language', query.language.toLowerCase());
    }
    if (query.codec) {
      params.set('codec', query.codec.toUpperCase());
    }
    if (query.workingOnly) {
      params.set('lastcheckok', '1');
    }

    return this.fetchJson<RawRadioBrowserStation[]>(
      `/json/stations/search?${params.toString()}`,
    );
  }

  getStationByUuid(id: string): Promise<RawRadioBrowserStation[]> {
    return this.fetchJson<RawRadioBrowserStation[]>(
      `/json/stations/byuuid/${encodeURIComponent(id)}`,
    );
  }
}
