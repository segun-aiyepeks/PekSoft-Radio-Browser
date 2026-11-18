import type {
  DeltaSyncRequest,
  FavoriteInput,
  RecentInput,
} from '@peksoft/shared';
import { getApiBaseUrl } from '@/lib/api-client';

export interface LibraryFavoriteRecord {
  stationId: string;
  stationName: string;
  streamUrl: string;
  countryCode: string;
  faviconUrl: string | null;
  codec: string | null;
  bitrateKbps: number | null;
  updatedAt: string;
}

export interface LibraryRecentRecord {
  stationId: string;
  stationName: string;
  streamUrl: string;
  countryCode: string;
  playedAt: string;
}

export interface LibraryCollectionRecord {
  id: string;
  name: string;
  description: string | null;
  items: Array<{
    stationId: string;
    stationName: string;
    streamUrl: string;
    countryCode: string;
    position: number;
  }>;
}

export interface LibrarySongHistoryRecord {
  id: string;
  stationId: string;
  stationName: string;
  trackTitle: string;
  heardAt: string;
}

export interface EntitlementSnapshot {
  plan: 'free' | 'plus';
  isPlus: boolean;
  source?: string | null;
  expiresAt?: string | null;
}

async function authedFetch<T>(
  path: string,
  token: string,
  init?: RequestInit,
): Promise<T | null> {
  const url = `${getApiBaseUrl()}${path}`;
  try {
    const res = await fetch(url, {
      ...init,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        ...(init?.headers ?? {}),
      },
    });
    if (res.status === 204) return null;
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null;
  }
}

export async function fetchEntitlements(
  token: string,
): Promise<EntitlementSnapshot | null> {
  return authedFetch<EntitlementSnapshot>('/v1/entitlements', token);
}

export async function fetchLibraryFavorites(
  token: string,
): Promise<LibraryFavoriteRecord[] | null> {
  const data = await authedFetch<{ items: LibraryFavoriteRecord[] }>(
    '/v1/library/favorites',
    token,
  );
  return data?.items ?? null;
}

export async function upsertLibraryFavorite(
  token: string,
  input: FavoriteInput,
): Promise<boolean> {
  const res = await authedFetch(
    `/v1/library/favorites/${encodeURIComponent(input.stationId)}`,
    token,
    {
      method: 'PUT',
      body: JSON.stringify(input),
    },
  );
  return res !== null;
}

export async function deleteLibraryFavorite(
  token: string,
  stationId: string,
): Promise<void> {
  await authedFetch(
    `/v1/library/favorites/${encodeURIComponent(stationId)}`,
    token,
    { method: 'DELETE' },
  );
}

export async function fetchLibraryRecents(
  token: string,
): Promise<LibraryRecentRecord[] | null> {
  const data = await authedFetch<{ items: LibraryRecentRecord[] }>(
    '/v1/library/recents',
    token,
  );
  return data?.items ?? null;
}

export async function upsertLibraryRecent(
  token: string,
  input: RecentInput,
): Promise<void> {
  await authedFetch(
    `/v1/library/recents/${encodeURIComponent(input.stationId)}`,
    token,
    {
      method: 'PUT',
      body: JSON.stringify(input),
    },
  );
}

export async function fetchLibraryCollections(
  token: string,
): Promise<LibraryCollectionRecord[] | null> {
  const data = await authedFetch<{ items: LibraryCollectionRecord[] }>(
    '/v1/library/collections',
    token,
  );
  return data?.items ?? null;
}

export async function fetchLibrarySongHistory(
  token: string,
): Promise<LibrarySongHistoryRecord[] | null> {
  const data = await authedFetch<{ items: LibrarySongHistoryRecord[] }>(
    '/v1/library/song-history',
    token,
  );
  return data?.items ?? null;
}

export async function deltaSyncLibrary(
  token: string,
  payload: DeltaSyncRequest,
): Promise<{
  favorites?: LibraryFavoriteRecord[];
  collections?: LibraryCollectionRecord[];
  recents?: LibraryRecentRecord[];
  songHistory?: LibrarySongHistoryRecord[];
} | null> {
  return authedFetch('/v1/sync', token, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}
