import {
  type CountryDto,
  type GenreDto,
  type LanguageDto,
  type StationDto,
  type StationNormaliser,
  type StationSearchQuery,
} from '@peksoft/shared';
import type { CacheStore } from '../cache/cache-store.js';
import { defaultStationNormaliser } from '../config/genre-map.js';
import { notFound } from '../errors/app-error.js';
import type { RadioBrowserClient } from '../repositories/radio-browser-client.js';

const CATALOG_TTL_MS = 6 * 60 * 60 * 1000;
const TRENDING_TTL_MS = 5 * 60 * 1000;
const SEARCH_TTL_MS = 2 * 60 * 1000;
const STATION_TTL_MS = 10 * 60 * 1000;

export class CatalogService {
  constructor(
    private readonly client: RadioBrowserClient,
    private readonly cache: CacheStore,
    private readonly normaliser: StationNormaliser = defaultStationNormaliser,
  ) {}

  async getCountries(): Promise<CountryDto[]> {
    const key = 'catalog:countries:v1';
    const cached = await this.cache.get<CountryDto[]>(key);
    if (cached) return cached;

    const raw = await this.client.getCountries();
    const countries = raw
      .filter((c) => c.iso_3166_1?.trim() && c.name?.trim() && c.stationcount > 0)
      .map((c) => ({
        code: c.iso_3166_1.trim().toUpperCase(),
        name: c.name.trim(),
        stationCount: c.stationcount,
      }));

    await this.cache.set(key, countries, CATALOG_TTL_MS);
    return countries;
  }

  async getGenres(): Promise<GenreDto[]> {
    const key = 'catalog:genres:v1';
    const cached = await this.cache.get<GenreDto[]>(key);
    if (cached) return cached;

    const rawTags = await this.client.getTags();
    const counts = new Map<string, number>();

    for (const tag of rawTags) {
      const mapped = this.normaliser.normalizeTags(tag.name);
      for (const genre of mapped) {
        counts.set(genre.id, (counts.get(genre.id) ?? 0) + tag.stationcount);
      }
    }

    const genres: GenreDto[] = this.normaliser.genreMap.genres
      .map((entry) => ({
        id: entry.id,
        name: entry.name,
        tagline: entry.tagline,
        stationCount: counts.get(entry.id) ?? 0,
      }))
      .sort((a, b) => b.stationCount - a.stationCount);

    await this.cache.set(key, genres, CATALOG_TTL_MS);
    return genres;
  }

  async getLanguages(): Promise<LanguageDto[]> {
    const key = 'catalog:languages:v1';
    const cached = await this.cache.get<LanguageDto[]>(key);
    if (cached) return cached;

    const raw = await this.client.getLanguages();
    const languages: LanguageDto[] = raw
      .filter((l) => l.name?.trim() && l.stationcount > 0)
      .map((l) => ({
        ...(l.iso_639?.trim() ? { code: l.iso_639.trim().toLowerCase() } : {}),
        name: l.name.trim(),
        stationCount: l.stationcount,
      }));

    await this.cache.set(key, languages, CATALOG_TTL_MS);
    return languages;
  }

  async getTrendingStations(options: {
    limit: number;
    country?: string;
    httpsOnly?: boolean;
    workingOnly: boolean;
  }): Promise<StationDto[]> {
    const key = `stations:trending:${JSON.stringify(options)}`;
    const cached = await this.cache.get<StationDto[]>(key);
    if (cached) return cached;

    const raw = await this.client.getTrendingStations(
      Math.min(100, options.limit * 2),
      options.country,
    );
    const filtered = this.applyPostFilters(
      this.normaliser.normalizeStations(raw),
      {
        workingOnly: options.workingOnly,
        httpsOnly: options.httpsOnly,
      },
    ).slice(0, options.limit);

    await this.cache.set(key, filtered, TRENDING_TTL_MS);
    return filtered;
  }

  async searchStations(query: StationSearchQuery): Promise<StationDto[]> {
    const key = `stations:search:${JSON.stringify(query)}`;
    const cached = await this.cache.get<StationDto[]>(key);
    if (cached) return cached;

    const raw = await this.client.searchStations(query);
    const normalized = this.normaliser.normalizeStations(raw);
    const filtered = this.applyPostFilters(normalized, query);

    const sorted = [...filtered].sort((a, b) => {
      if (query.sort === 'votes') {
        return b.votes - a.votes;
      }
      return b.clickCount - a.clickCount;
    });

    const paged = sorted.slice(query.offset, query.offset + query.limit);
    await this.cache.set(key, paged, SEARCH_TTL_MS);
    return paged;
  }

  async getStationById(id: string): Promise<StationDto> {
    const key = `stations:byId:${id}`;
    const cached = await this.cache.get<StationDto>(key);
    if (cached) return cached;

    const raw = await this.client.getStationByUuid(id);
    const normalized = this.normaliser.normalizeStations(raw);
    const station = normalized[0];
    if (!station) {
      throw notFound(`Station ${id} not found`);
    }

    await this.cache.set(key, station, STATION_TTL_MS);
    return station;
  }

  private applyPostFilters(
    stations: StationDto[],
    filter: {
      workingOnly: boolean;
      httpsOnly?: boolean;
      minBitrate?: number;
      codec?: string;
      country?: string;
      genre?: string;
      q?: string;
    },
  ): StationDto[] {
    const qLower = filter.q?.trim().toLowerCase();
    const genreLower = filter.genre?.trim().toLowerCase();
    const countryUpper = filter.country?.trim().toUpperCase();
    const codecUpper = filter.codec?.trim().toUpperCase();

    return stations.filter((s) => {
      if (filter.workingOnly && !s.isWorking) return false;
      if (filter.httpsOnly && !s.isHttpsPlayable) return false;
      if (
        filter.minBitrate !== undefined &&
        s.bitrateKbps < filter.minBitrate
      ) {
        return false;
      }
      if (codecUpper && !s.codec.toUpperCase().includes(codecUpper)) {
        return false;
      }
      if (countryUpper && s.countryCode !== countryUpper) return false;
      if (
        genreLower &&
        !s.genres.some(
          (g) =>
            g.id.toLowerCase() === genreLower ||
            g.name.toLowerCase() === genreLower,
        )
      ) {
        return false;
      }
      if (
        qLower &&
        !s.name.toLowerCase().includes(qLower) &&
        !s.countryName.toLowerCase().includes(qLower) &&
        !s.genres.some((g) => g.name.toLowerCase().includes(qLower))
      ) {
        return false;
      }
      return true;
    });
  }
}
