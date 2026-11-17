import {
  countrySchema,
  genreSchema,
  languageSchema,
  stationSchema,
  type CountryDto,
  type GenreDto,
  type LanguageDto,
  type StationDto,
  type StationSearchQuery,
} from '@peksoft/shared';
import {
  MOCK_COUNTRIES,
  MOCK_GENRES,
  MOCK_STATIONS,
  getCountryByCode,
  getGenreBySlug,
  getStationBySlug,
  type WebCountry,
  type WebGenre,
  type WebStation,
} from '@/lib/mock-data';

const GENRE_GRADIENTS: Record<string, string> = {
  afrobeats: 'from-amber-500/35 via-orange-600/20 to-slate-900',
  jazz: 'from-indigo-500/35 via-blue-600/20 to-slate-900',
  news: 'from-emerald-500/30 via-teal-600/20 to-slate-900',
  electronic: 'from-fuchsia-500/30 via-purple-600/20 to-slate-900',
  classical: 'from-sky-500/30 via-cyan-600/20 to-slate-900',
  gospel: 'from-yellow-500/30 via-amber-600/20 to-slate-900',
};

export function getApiBaseUrl(): string {
  return (
    process.env.API_URL ||
    process.env.NEXT_PUBLIC_API_URL ||
    'http://127.0.0.1:4000'
  ).replace(/\/+$/, '');
}

export function countryCodeToFlag(code: string): string {
  const upper = code.trim().toUpperCase();
  if (!/^[A-Z]{2}$/.test(upper)) return '🌍';
  return String.fromCodePoint(
    0x1f1e6 + upper.charCodeAt(0) - 65,
    0x1f1e6 + upper.charCodeAt(1) - 65,
  );
}

export function slugifyStationName(name: string, id: string): string {
  const base = name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
  const shortId = id.slice(0, 8);
  return base ? `${base}-${shortId}` : id;
}

export function stationDtoToWebStation(dto: StationDto): WebStation {
  return {
    id: dto.id,
    slug: slugifyStationName(dto.name, dto.id),
    name: dto.name,
    streamUrl: dto.streamUrl,
    fallbackStreamUrl: dto.fallbackStreamUrl,
    homepage: dto.homepage ?? '',
    faviconUrl: dto.faviconUrl ?? null,
    isHttps: dto.isHttps,
    isHttpsPlayable: dto.isHttpsPlayable,
    isHls: dto.isHls,
    isWorking: dto.isWorking,
    countryCode: dto.countryCode || 'XX',
    countryName: dto.countryName || 'Global',
    countryFlag: countryCodeToFlag(dto.countryCode || ''),
    genres: dto.genres.map((g) => g.id),
    language: dto.language ?? 'Multilingual',
    codec: dto.codec || 'MP3',
    bitrateKbps: dto.bitrateKbps ?? 0,
    votes: dto.votes ?? 0,
    clickCount: dto.clickCount ?? 0,
  };
}

export function countryDtoToWebCountry(dto: CountryDto): WebCountry {
  return {
    code: dto.code,
    name: dto.name,
    flag: countryCodeToFlag(dto.code),
    stationCount: dto.stationCount,
    workingCount: dto.stationCount,
  };
}

export function genreDtoToWebGenre(dto: GenreDto): WebGenre {
  return {
    id: dto.id,
    slug: dto.id,
    name: dto.name,
    tagline: dto.tagline ?? 'Live stations curated by genre',
    stationCount: dto.stationCount,
    gradient:
      GENRE_GRADIENTS[dto.id] ??
      'from-amber-500/25 via-slate-800 to-slate-950',
  };
}

interface SafeParseSchema<T> {
  safeParse: (
    data: unknown,
  ) => { success: true; data: T } | { success: false };
}

async function fetchJson(
  path: string,
  revalidateSeconds: number,
): Promise<Record<string, unknown> | null> {
  const url = `${getApiBaseUrl()}${path}`;
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 3000);
    const res = await fetch(url, {
      signal: controller.signal,
      next: { revalidate: revalidateSeconds },
    });
    clearTimeout(timer);
    if (!res.ok) return null;
    const json: unknown = await res.json();
    if (!json || typeof json !== 'object') return null;
    return json as Record<string, unknown>;
  } catch {
    return null;
  }
}

async function fetchItemsWithSchema<T>(
  path: string,
  itemSchema: SafeParseSchema<T>,
  revalidateSeconds: number,
): Promise<T[] | null> {
  const json = await fetchJson(path, revalidateSeconds);
  if (!json || !Array.isArray(json.items)) return null;
  const parsed: T[] = [];
  for (const raw of json.items) {
    const result = itemSchema.safeParse(raw);
    if (result.success) {
      parsed.push(result.data);
    }
  }
  return parsed;
}

export async function fetchCountries(): Promise<WebCountry[]> {
  const items = await fetchItemsWithSchema(
    '/v1/catalog/countries',
    countrySchema,
    3600,
  );
  if (items && items.length > 0) {
    return items.map(countryDtoToWebCountry);
  }
  return MOCK_COUNTRIES;
}

export async function fetchGenres(): Promise<WebGenre[]> {
  const items = await fetchItemsWithSchema(
    '/v1/catalog/genres',
    genreSchema,
    3600,
  );
  if (items && items.length > 0) {
    return items.map(genreDtoToWebGenre);
  }
  return MOCK_GENRES;
}

export async function fetchLanguages(): Promise<LanguageDto[]> {
  const items = await fetchItemsWithSchema(
    '/v1/catalog/languages',
    languageSchema,
    3600,
  );
  if (items && items.length > 0) {
    return items;
  }
  return [
    { name: 'English', stationCount: 4200 },
    { name: 'French', stationCount: 980 },
    { name: 'Spanish', stationCount: 1540 },
    { name: 'Portuguese', stationCount: 820 },
    { name: 'Japanese', stationCount: 410 },
  ];
}

export async function fetchTrendingStations(options?: {
  limit?: number;
  country?: string;
  httpsOnly?: boolean;
  workingOnly?: boolean;
}): Promise<WebStation[]> {
  const params = new URLSearchParams();
  if (options?.limit) params.set('limit', String(options.limit));
  if (options?.country) params.set('country', options.country);
  if (options?.httpsOnly !== undefined) {
    params.set('httpsOnly', String(options.httpsOnly));
  }
  if (options?.workingOnly !== undefined) {
    params.set('workingOnly', String(options.workingOnly));
  }
  const qs = params.toString();
  const items = await fetchItemsWithSchema(
    `/v1/stations/trending${qs ? `?${qs}` : ''}`,
    stationSchema,
    120,
  );
  if (items && items.length > 0) {
    return items.map(stationDtoToWebStation);
  }
  return MOCK_STATIONS.filter((s) =>
    options?.country
      ? s.countryCode.toLowerCase() === options.country.toLowerCase()
      : true,
  );
}

export async function searchStations(
  query: Partial<StationSearchQuery>,
): Promise<WebStation[]> {
  const params = new URLSearchParams();
  if (query.q) params.set('q', query.q);
  if (query.country) params.set('country', query.country);
  if (query.genre) params.set('genre', query.genre);
  if (query.language) params.set('language', query.language);
  if (query.codec) params.set('codec', query.codec);
  if (query.minBitrate !== undefined) {
    params.set('minBitrate', String(query.minBitrate));
  }
  if (query.httpsOnly !== undefined) {
    params.set('httpsOnly', String(query.httpsOnly));
  }
  if (query.workingOnly !== undefined) {
    params.set('workingOnly', String(query.workingOnly));
  }
  if (query.sort) params.set('sort', query.sort);
  if (query.limit) params.set('limit', String(query.limit));
  if (query.offset) params.set('offset', String(query.offset));

  const qs = params.toString();
  const items = await fetchItemsWithSchema(
    `/v1/stations/search${qs ? `?${qs}` : ''}`,
    stationSchema,
    60,
  );
  if (items && items.length > 0) {
    return items.map(stationDtoToWebStation);
  }
  return MOCK_STATIONS.filter((s) => {
    if (
      query.country &&
      s.countryCode.toLowerCase() !== query.country.toLowerCase()
    ) {
      return false;
    }
    if (query.genre && !s.genres.includes(query.genre)) {
      return false;
    }
    if (query.httpsOnly && !s.isHttpsPlayable) return false;
    if (query.workingOnly !== false && !s.isWorking) return false;
    return true;
  });
}

export async function fetchStationBySlugOrId(
  slugOrId: string,
): Promise<WebStation | null> {
  const mockMatch = getStationBySlug(slugOrId);
  if (mockMatch) return mockMatch;

  const json = await fetchJson(
    `/v1/stations/${encodeURIComponent(slugOrId)}`,
    300,
  );
  if (json && 'station' in json) {
    const parsed = stationSchema.safeParse(json.station);
    if (parsed.success) {
      return stationDtoToWebStation(parsed.data);
    }
  }

  // Try matching by slug suffix or name search if slugOrId is a generated slug
  const trending = await fetchTrendingStations({ limit: 40 });
  const found = trending.find(
    (s) => s.slug === slugOrId || s.id === slugOrId,
  );
  return found ?? null;
}

export async function fetchCountryMeta(code: string): Promise<WebCountry> {
  const countries = await fetchCountries();
  const match =
    countries.find((c) => c.code.toLowerCase() === code.toLowerCase()) ??
    getCountryByCode(code);
  if (match) return match;
  const upper = code.toUpperCase();
  return {
    code: upper,
    name: upper,
    flag: countryCodeToFlag(upper),
    stationCount: 0,
    workingCount: 0,
  };
}

export async function fetchGenreMeta(slug: string): Promise<WebGenre> {
  const genres = await fetchGenres();
  const match =
    genres.find((g) => g.slug.toLowerCase() === slug.toLowerCase()) ??
    getGenreBySlug(slug);
  if (match) return match;
  return {
    id: slug,
    slug,
    name: slug.charAt(0).toUpperCase() + slug.slice(1),
    tagline: 'Live stations tagged with this genre',
    stationCount: 0,
    gradient:
      GENRE_GRADIENTS[slug] ?? 'from-amber-500/30 via-slate-800 to-slate-950',
  };
}
