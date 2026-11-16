import { z } from 'zod';

export interface GenreMapEntry {
  id: string;
  name: string;
  tagline: string;
  aliases: string[];
}

export interface GenreMapConfig {
  version: number;
  maxGenresPerStation: number;
  noiseTags: string[];
  genres: GenreMapEntry[];
}

export const genreSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  tagline: z.string().optional(),
  stationCount: z.number().int().nonnegative().default(0),
});
export type GenreDto = z.infer<typeof genreSchema>;

export const countrySchema = z.object({
  code: z.string().min(1),
  name: z.string().min(1),
  stationCount: z.number().int().nonnegative(),
});
export type CountryDto = z.infer<typeof countrySchema>;

export const languageSchema = z.object({
  code: z.string().optional(),
  name: z.string().min(1),
  stationCount: z.number().int().nonnegative(),
});
export type LanguageDto = z.infer<typeof languageSchema>;

export const stationSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  streamUrl: z.string().url(),
  fallbackStreamUrl: z.string().url().optional(),
  homepage: z.string().optional(),
  faviconUrl: z.string().optional(),
  usesFallbackLogo: z.boolean(),
  isHttps: z.boolean(),
  /** True when the stream uses HTTPS without reported SSL errors so web browsers can play it without mixed-content blocks. */
  isHttpsPlayable: z.boolean(),
  isHls: z.boolean(),
  isWorking: z.boolean(),
  countryCode: z.string(),
  countryName: z.string(),
  state: z.string().optional(),
  genres: z.array(genreSchema),
  language: z.string().optional(),
  codec: z.string(),
  bitrateKbps: z.number().int().nonnegative(),
  votes: z.number().int().nonnegative(),
  clickCount: z.number().int().nonnegative(),
  clickTrend: z.number().int(),
});
export type StationDto = z.infer<typeof stationSchema>;

export const stationSearchQuerySchema = z.object({
  q: z.string().trim().max(100).optional(),
  country: z.string().trim().min(2).max(4).optional(),
  genre: z.string().trim().max(60).optional(),
  language: z.string().trim().max(60).optional(),
  codec: z.string().trim().max(20).optional(),
  minBitrate: z.coerce.number().int().nonnegative().max(1000).optional(),
  httpsOnly: z
    .union([z.boolean(), z.enum(['true', 'false'])])
    .transform((v) => v === true || v === 'true')
    .optional(),
  workingOnly: z
    .union([z.boolean(), z.enum(['true', 'false'])])
    .transform((v) => v === true || v === 'true')
    .default(true),
  sort: z.enum(['popular', 'votes', 'recent']).default('popular'),
  limit: z.coerce.number().int().positive().max(100).default(40),
  offset: z.coerce.number().int().nonnegative().max(1000).default(0),
});
export type StationSearchQuery = z.infer<typeof stationSearchQuerySchema>;

export interface RawRadioBrowserStation {
  stationuuid: string;
  name: string;
  url: string;
  url_resolved?: string;
  homepage?: string;
  favicon?: string;
  tags?: string;
  country?: string;
  countrycode?: string;
  state?: string;
  language?: string;
  votes?: number;
  clickcount?: number;
  clicktrend?: number;
  codec?: string;
  bitrate?: number;
  hls?: number;
  lastcheckok?: number;
  ssl_error?: number;
}

export interface RawRadioBrowserCountry {
  name: string;
  iso_3166_1: string;
  stationcount: number;
}

export interface RawRadioBrowserTag {
  name: string;
  stationcount: number;
}

export interface RawRadioBrowserLanguage {
  name: string;
  iso_639: string | null;
  stationcount: number;
}

function isHttpUrl(value: string | undefined): value is string {
  if (!value) return false;
  const trimmed = value.trim();
  return trimmed.startsWith('https://') || trimmed.startsWith('http://');
}

function stationDedupeKey(station: StationDto): string {
  let host = '';
  try {
    host = new URL(station.streamUrl).hostname.toLowerCase();
  } catch {
    host = station.streamUrl.toLowerCase();
  }
  const normalizedName = station.name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
  return `${normalizedName}|${station.countryCode}|${host}`;
}

function isBetterCandidate(candidate: StationDto, current: StationDto): boolean {
  if (candidate.isHttpsPlayable !== current.isHttpsPlayable) {
    return candidate.isHttpsPlayable;
  }
  if (candidate.isWorking !== current.isWorking) {
    return candidate.isWorking;
  }
  return candidate.clickCount > current.clickCount;
}

export interface StationNormaliser {
  genreMap: GenreMapConfig;
  normalizeTags(rawTags: string | undefined): GenreDto[];
  normalizeStation(raw: RawRadioBrowserStation): StationDto | null;
  normalizeStations(rawList: RawRadioBrowserStation[]): StationDto[];
}

export function createStationNormaliser(
  genreMap: GenreMapConfig,
): StationNormaliser {
  const noiseTagSet = new Set(
    genreMap.noiseTags.map((t) => t.trim().toLowerCase()),
  );

  const aliasToGenre = new Map<string, GenreDto>();
  for (const entry of genreMap.genres) {
    const dto: GenreDto = {
      id: entry.id,
      name: entry.name,
      tagline: entry.tagline,
      stationCount: 0,
    };
    aliasToGenre.set(entry.id.toLowerCase(), dto);
    aliasToGenre.set(entry.name.toLowerCase(), dto);
    for (const alias of entry.aliases) {
      aliasToGenre.set(alias.trim().toLowerCase(), dto);
    }
  }

  function normalizeTags(rawTags: string | undefined): GenreDto[] {
    if (!rawTags || rawTags.trim().length === 0) {
      return [];
    }

    const matched = new Map<string, GenreDto>();
    const parts = rawTags.split(',');

    for (const rawPart of parts) {
      const token = rawPart.trim().toLowerCase();
      if (!token || noiseTagSet.has(token)) {
        continue;
      }
      const canonical = aliasToGenre.get(token);
      if (canonical && !matched.has(canonical.id)) {
        matched.set(canonical.id, canonical);
        if (matched.size >= genreMap.maxGenresPerStation) {
          break;
        }
      }
    }

    return Array.from(matched.values());
  }

  function normalizeStation(raw: RawRadioBrowserStation): StationDto | null {
    const resolved = raw.url_resolved?.trim() ?? '';
    const original = raw.url?.trim() ?? '';
    const streamUrl = isHttpUrl(resolved)
      ? resolved
      : isHttpUrl(original)
        ? original
        : '';

    if (!raw.stationuuid || !raw.name?.trim() || !streamUrl) {
      return null;
    }

    const fallbackStreamUrl =
      isHttpUrl(original) && original !== streamUrl ? original : undefined;
    const faviconRaw = raw.favicon?.trim() ?? '';
    const hasValidFavicon = isHttpUrl(faviconRaw);

    const isHttps = streamUrl.startsWith('https://');
    const hasSslError = raw.ssl_error === 1;
    const isWorking = raw.lastcheckok === 1 && streamUrl.length > 0;

    return {
      id: raw.stationuuid,
      name: raw.name.trim(),
      streamUrl,
      ...(fallbackStreamUrl ? { fallbackStreamUrl } : {}),
      ...(isHttpUrl(raw.homepage?.trim())
        ? { homepage: raw.homepage!.trim() }
        : {}),
      ...(hasValidFavicon ? { faviconUrl: faviconRaw } : {}),
      usesFallbackLogo: !hasValidFavicon,
      isHttps,
      isHttpsPlayable: isHttps && !hasSslError,
      isHls: raw.hls === 1,
      isWorking,
      countryCode: (raw.countrycode ?? '').trim().toUpperCase(),
      countryName: (raw.country ?? '').trim(),
      ...(raw.state?.trim() ? { state: raw.state.trim() } : {}),
      genres: normalizeTags(raw.tags),
      ...(raw.language?.trim() ? { language: raw.language.trim() } : {}),
      codec: (raw.codec?.trim() || 'UNKNOWN').toUpperCase(),
      bitrateKbps: Math.max(0, Math.trunc(raw.bitrate ?? 0)),
      votes: Math.max(0, Math.trunc(raw.votes ?? 0)),
      clickCount: Math.max(0, Math.trunc(raw.clickcount ?? 0)),
      clickTrend: Math.trunc(raw.clicktrend ?? 0),
    };
  }

  function normalizeStations(rawList: RawRadioBrowserStation[]): StationDto[] {
    const byId = new Map<string, StationDto>();
    for (const raw of rawList) {
      const normalized = normalizeStation(raw);
      if (normalized && !byId.has(normalized.id)) {
        byId.set(normalized.id, normalized);
      }
    }

    const bySignature = new Map<string, StationDto>();
    for (const station of byId.values()) {
      const key = stationDedupeKey(station);
      const existing = bySignature.get(key);
      if (!existing || isBetterCandidate(station, existing)) {
        bySignature.set(key, station);
      }
    }

    return Array.from(bySignature.values());
  }

  return {
    genreMap,
    normalizeTags,
    normalizeStation,
    normalizeStations,
  };
}
