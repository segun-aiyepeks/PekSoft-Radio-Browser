import type {
  CollectionInput,
  CollectionItemInput,
  FavoriteInput,
  RecentInput,
  SongHistoryInput,
  StationReportInput,
} from '@peksoft/shared';
import { randomUUID } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import type { AuthProvider, VerifiedIdentity } from './auth/firebase-auth.js';
import type { Env } from './config/env.js';
import { unauthorized } from './errors/app-error.js';
import type {
  CollectionItemRecord,
  CollectionRecord,
  FavoriteRecord,
  LibraryRepository,
  RecentRecord,
  SongHistoryRecord,
} from './repositories/library-repository.js';
import type {
  ReportRepository,
  StationReportRecord,
} from './repositories/report-repository.js';
import type {
  UserRepository,
  UserWithEntitlementRecord,
} from './repositories/user-repository.js';
import { buildServer } from './server.js';

class FakeAuthProvider implements AuthProvider {
  private readonly tokens = new Map<string, VerifiedIdentity>();
  setToken(token: string, identity: VerifiedIdentity) {
    this.tokens.set(token, identity);
  }
  async verifyIdToken(idToken: string): Promise<VerifiedIdentity> {
    const match = this.tokens.get(idToken);
    if (!match) throw unauthorized('Invalid token');
    return match;
  }
  async deleteUser(): Promise<void> {}
}

class InMemoryUserRepo implements UserRepository {
  readonly users = new Map<string, UserWithEntitlementRecord>();
  constructor(private readonly plusUids = new Set<string>()) {}

  async findOrCreateByFirebaseUid(
    identity: VerifiedIdentity,
  ): Promise<UserWithEntitlementRecord> {
    const existing = this.users.get(identity.uid);
    if (existing) return existing;
    const now = new Date();
    const record: UserWithEntitlementRecord = {
      id: randomUUID(),
      firebaseUid: identity.uid,
      email: identity.email ?? null,
      displayName: identity.displayName ?? null,
      createdAt: now,
      updatedAt: now,
      entitlement: {
        tier: this.plusUids.has(identity.uid) ? 'PLUS' : 'FREE',
        status: 'ACTIVE',
        source: this.plusUids.has(identity.uid) ? 'GOOGLE_PLAY' : 'NONE',
        expiresAt: null,
      },
    };
    this.users.set(identity.uid, record);
    return record;
  }

  async deleteByFirebaseUid(firebaseUid: string): Promise<boolean> {
    return this.users.delete(firebaseUid);
  }
}

class InMemoryLibraryRepo implements LibraryRepository {
  favorites: FavoriteRecord[] = [];
  collections: CollectionRecord[] = [];
  recents: RecentRecord[] = [];
  songHistory: SongHistoryRecord[] = [];

  async listFavorites(userId: string, since?: Date): Promise<FavoriteRecord[]> {
    return this.favorites.filter(
      (f) =>
        f.userId === userId &&
        (since ? f.updatedAt.getTime() > since.getTime() : !f.isDeleted),
    );
  }

  async findFavorite(
    userId: string,
    stationId: string,
  ): Promise<FavoriteRecord | null> {
    return (
      this.favorites.find(
        (f) => f.userId === userId && f.stationId === stationId,
      ) ?? null
    );
  }

  async countActiveFavorites(userId: string): Promise<number> {
    return this.favorites.filter((f) => f.userId === userId && !f.isDeleted)
      .length;
  }

  async upsertFavoriteLww(
    userId: string,
    input: FavoriteInput,
    updatedAt: Date,
  ): Promise<{ record: FavoriteRecord; applied: boolean }> {
    const existing = await this.findFavorite(userId, input.stationId);
    if (existing && existing.updatedAt.getTime() > updatedAt.getTime()) {
      return { record: existing, applied: false };
    }
    if (existing) {
      Object.assign(existing, {
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        faviconUrl: input.faviconUrl ?? null,
        codec: input.codec ?? null,
        bitrateKbps: input.bitrateKbps ?? null,
        isDeleted: input.isDeleted,
        updatedAt,
      });
      return { record: existing, applied: true };
    }
    const created: FavoriteRecord = {
      id: randomUUID(),
      userId,
      stationId: input.stationId,
      stationName: input.stationName,
      streamUrl: input.streamUrl,
      countryCode: input.countryCode,
      faviconUrl: input.faviconUrl ?? null,
      codec: input.codec ?? null,
      bitrateKbps: input.bitrateKbps ?? null,
      isDeleted: input.isDeleted,
      createdAt: updatedAt,
      updatedAt,
    };
    this.favorites.push(created);
    return { record: created, applied: true };
  }

  async listCollections(
    userId: string,
    since?: Date,
  ): Promise<CollectionRecord[]> {
    return this.collections
      .filter(
        (c) =>
          c.userId === userId &&
          (since ? c.updatedAt.getTime() > since.getTime() : !c.isDeleted),
      )
      .map((c) => ({
        ...c,
        items: c.items.filter((i) =>
          since ? i.updatedAt.getTime() > since.getTime() : !i.isDeleted,
        ),
      }));
  }

  async findCollection(
    userId: string,
    collectionId: string,
  ): Promise<CollectionRecord | null> {
    return (
      this.collections.find(
        (c) => c.userId === userId && c.id === collectionId,
      ) ?? null
    );
  }

  async countActiveCollections(userId: string): Promise<number> {
    return this.collections.filter((c) => c.userId === userId && !c.isDeleted)
      .length;
  }

  async upsertCollectionLww(
    userId: string,
    input: CollectionInput,
    updatedAt: Date,
  ): Promise<{ record: CollectionRecord; applied: boolean }> {
    const existing = input.id
      ? await this.findCollection(userId, input.id)
      : null;
    if (existing && existing.updatedAt.getTime() > updatedAt.getTime()) {
      return { record: existing, applied: false };
    }
    if (existing) {
      existing.name = input.name;
      existing.description = input.description ?? null;
      existing.isDeleted = input.isDeleted;
      existing.updatedAt = updatedAt;
      return { record: existing, applied: true };
    }
    const created: CollectionRecord = {
      id: input.id ?? randomUUID(),
      userId,
      name: input.name,
      description: input.description ?? null,
      isDeleted: input.isDeleted,
      createdAt: updatedAt,
      updatedAt,
      items: [],
    };
    this.collections.push(created);
    return { record: created, applied: true };
  }

  async upsertCollectionItemLww(
    userId: string,
    collectionId: string,
    input: CollectionItemInput,
    updatedAt: Date,
  ): Promise<{ record: CollectionItemRecord; applied: boolean } | null> {
    const col = await this.findCollection(userId, collectionId);
    if (!col) return null;
    const existing = col.items.find((i) => i.stationId === input.stationId);
    if (existing && existing.updatedAt.getTime() > updatedAt.getTime()) {
      return { record: existing, applied: false };
    }
    if (existing) {
      Object.assign(existing, {
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        position: input.position,
        isDeleted: input.isDeleted,
        updatedAt,
      });
      col.updatedAt = updatedAt;
      return { record: existing, applied: true };
    }
    const created: CollectionItemRecord = {
      id: randomUUID(),
      collectionId,
      stationId: input.stationId,
      stationName: input.stationName,
      streamUrl: input.streamUrl,
      countryCode: input.countryCode,
      position: input.position,
      isDeleted: input.isDeleted,
      createdAt: updatedAt,
      updatedAt,
    };
    col.items.push(created);
    col.updatedAt = updatedAt;
    return { record: created, applied: true };
  }

  async listRecents(userId: string, since?: Date): Promise<RecentRecord[]> {
    return this.recents.filter(
      (r) =>
        r.userId === userId &&
        (!since || r.updatedAt.getTime() > since.getTime()),
    );
  }

  async upsertRecentLww(
    userId: string,
    input: RecentInput,
    playedAt: Date,
    updatedAt: Date,
  ): Promise<{ record: RecentRecord; applied: boolean }> {
    const existing = this.recents.find(
      (r) => r.userId === userId && r.stationId === input.stationId,
    );
    if (existing && existing.updatedAt.getTime() > updatedAt.getTime()) {
      return { record: existing, applied: false };
    }
    if (existing) {
      Object.assign(existing, {
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        playedAt,
        updatedAt,
      });
      return { record: existing, applied: true };
    }
    const created: RecentRecord = {
      id: randomUUID(),
      userId,
      stationId: input.stationId,
      stationName: input.stationName,
      streamUrl: input.streamUrl,
      countryCode: input.countryCode,
      playedAt,
      updatedAt,
    };
    this.recents.push(created);
    return { record: created, applied: true };
  }

  async listSongHistory(
    userId: string,
    since?: Date,
  ): Promise<SongHistoryRecord[]> {
    return this.songHistory.filter(
      (s) =>
        s.userId === userId &&
        (!since || s.updatedAt.getTime() > since.getTime()),
    );
  }

  async addSongHistory(
    userId: string,
    input: SongHistoryInput,
    heardAt: Date,
    updatedAt: Date,
    maxRetention?: number | null,
  ): Promise<SongHistoryRecord> {
    const created: SongHistoryRecord = {
      id: randomUUID(),
      userId,
      stationId: input.stationId,
      stationName: input.stationName,
      trackTitle: input.trackTitle,
      heardAt,
      updatedAt,
    };
    this.songHistory.push(created);
    if (maxRetention && maxRetention > 0) {
      const userSongs = this.songHistory
        .filter((s) => s.userId === userId)
        .sort((a, b) => b.heardAt.getTime() - a.heardAt.getTime());
      const keepIds = new Set(userSongs.slice(0, maxRetention).map((s) => s.id));
      this.songHistory = this.songHistory.filter(
        (s) => s.userId !== userId || keepIds.has(s.id),
      );
    }
    return created;
  }
}

class InMemoryReportRepo implements ReportRepository {
  readonly reports: StationReportRecord[] = [];
  async createReport(options: {
    userId: string | null;
    input: StationReportInput;
  }): Promise<StationReportRecord> {
    const record: StationReportRecord = {
      id: randomUUID(),
      userId: options.userId,
      stationId: options.input.stationId,
      stationName: options.input.stationName,
      reason: options.input.reason,
      notes: options.input.notes ?? null,
      status: 'OPEN',
      createdAt: new Date(),
    };
    this.reports.push(record);
    return record;
  }
}

function makeTestEnv(): Env {
  return {
    PORT: 4000,
    HOST: '0.0.0.0',
    NODE_ENV: 'test',
    LOG_LEVEL: 'silent',
    CORS_ORIGINS: '*',
    RATE_LIMIT_MAX: 200,
    RATE_LIMIT_WINDOW_MS: 60_000,
    APP_VERSION: '0.1.0',
  };
}

describe('Milestone 4.5 Library sync API & StationReport', () => {
  it('enforces last-write-wins on favourites and free-tier 10-favourite cap', async () => {
    const auth = new FakeAuthProvider();
    auth.setToken('free-user', {
      uid: 'uid-free',
      email: 'free@example.com',
      emailVerified: true,
    });
    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: new InMemoryUserRepo(),
      libraryRepository: new InMemoryLibraryRepo(),
      reportRepository: new InMemoryReportRepo(),
    });

    // Insert with newer timestamp, then attempt overwrite with older timestamp
    const newerRes = await app.inject({
      method: 'PUT',
      url: '/v1/library/favorites/st-1',
      headers: { authorization: 'Bearer free-user' },
      payload: {
        stationName: 'FIP Newer',
        streamUrl: 'https://stream.example.com/fip.mp3',
        countryCode: 'FR',
        updatedAt: '2026-11-16T12:00:00.000Z',
      },
    });
    expect(newerRes.statusCode).toBe(200);
    expect(newerRes.json().applied).toBe(true);

    const staleRes = await app.inject({
      method: 'PUT',
      url: '/v1/library/favorites/st-1',
      headers: { authorization: 'Bearer free-user' },
      payload: {
        stationName: 'FIP Stale',
        streamUrl: 'https://stream.example.com/fip.mp3',
        countryCode: 'FR',
        updatedAt: '2026-11-16T11:00:00.000Z',
      },
    });
    expect(staleRes.statusCode).toBe(200);
    expect(staleRes.json().applied).toBe(false);
    expect(staleRes.json().record.stationName).toBe('FIP Newer');

    // Fill remaining 9 free favourite slots (total 10)
    for (let i = 2; i <= 10; i++) {
      const res = await app.inject({
        method: 'PUT',
        url: `/v1/library/favorites/st-${i}`,
        headers: { authorization: 'Bearer free-user' },
        payload: {
          stationName: `Station ${i}`,
          streamUrl: `https://stream.example.com/${i}.mp3`,
          countryCode: 'NG',
        },
      });
      expect(res.statusCode).toBe(200);
    }

    // 11th favourite is blocked by server-side free-tier limit
    const eleventh = await app.inject({
      method: 'PUT',
      url: '/v1/library/favorites/st-11',
      headers: { authorization: 'Bearer free-user' },
      payload: {
        stationName: 'Station 11',
        streamUrl: 'https://stream.example.com/11.mp3',
        countryCode: 'NG',
      },
    });
    expect(eleventh.statusCode).toBe(403);
    expect(eleventh.json().error.code).toBe('TIER_LIMIT_REACHED');

    // Soft-deleting one frees a slot
    await app.inject({
      method: 'DELETE',
      url: '/v1/library/favorites/st-2',
      headers: { authorization: 'Bearer free-user' },
    });
    const retry11 = await app.inject({
      method: 'PUT',
      url: '/v1/library/favorites/st-11',
      headers: { authorization: 'Bearer free-user' },
      payload: {
        stationName: 'Station 11',
        streamUrl: 'https://stream.example.com/11.mp3',
        countryCode: 'NG',
      },
    });
    expect(retry11.statusCode).toBe(200);

    await app.close();
  });

  it('enforces free-tier collection cap, song history retention, and delta-sync', async () => {
    const auth = new FakeAuthProvider();
    auth.setToken('free-user', {
      uid: 'uid-free-2',
      email: 'free2@example.com',
      emailVerified: true,
    });
    auth.setToken('plus-user', {
      uid: 'uid-plus',
      email: 'plus@example.com',
      emailVerified: true,
    });

    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: new InMemoryUserRepo(new Set(['uid-plus'])),
      libraryRepository: new InMemoryLibraryRepo(),
      reportRepository: new InMemoryReportRepo(),
    });

    // Free user can create 2 collections, 3rd returns 403
    for (let i = 1; i <= 2; i++) {
      const col = await app.inject({
        method: 'POST',
        url: '/v1/library/collections',
        headers: { authorization: 'Bearer free-user' },
        payload: { name: `Collection ${i}` },
      });
      expect(col.statusCode).toBe(201);
    }
    const thirdCol = await app.inject({
      method: 'POST',
      url: '/v1/library/collections',
      headers: { authorization: 'Bearer free-user' },
      payload: { name: 'Collection 3' },
    });
    expect(thirdCol.statusCode).toBe(403);

    // Song history capped at 10 for free user
    for (let i = 1; i <= 12; i++) {
      await app.inject({
        method: 'POST',
        url: '/v1/library/song-history',
        headers: { authorization: 'Bearer free-user' },
        payload: {
          stationId: 'st-1',
          stationName: 'FIP',
          trackTitle: `Track ${i}`,
          heardAt: new Date(1_700_000_000_000 + i * 1000).toISOString(),
        },
      });
    }
    const historyRes = await app.inject({
      method: 'GET',
      url: '/v1/library/song-history',
      headers: { authorization: 'Bearer free-user' },
    });
    expect(historyRes.statusCode).toBe(200);
    expect(historyRes.json().items).toHaveLength(10);

    // Delta-sync returns only changes after `since` and rejects over-limit items for FREE
    const syncRes = await app.inject({
      method: 'POST',
      url: '/v1/sync',
      headers: { authorization: 'Bearer free-user' },
      payload: {
        since: '2026-11-16T00:00:00.000Z',
        collections: [
          {
            name: 'Extra Synced Collection',
            updatedAt: '2026-11-16T12:10:00.000Z',
          },
        ],
        recents: [
          {
            stationId: 'st-recent-1',
            stationName: 'Lagos Beat',
            streamUrl: 'https://stream.example.com/lagos.mp3',
            countryCode: 'NG',
            playedAt: '2026-11-16T12:10:00.000Z',
          },
        ],
      },
    });
    expect(syncRes.statusCode).toBe(200);
    expect(syncRes.json().rejected).toHaveLength(1);
    expect(syncRes.json().rejected[0].code).toBe('TIER_LIMIT_REACHED');
    expect(syncRes.json().changes.recents).toHaveLength(1);

    // Plus user has no 10-favourite limit
    for (let i = 1; i <= 12; i++) {
      const res = await app.inject({
        method: 'PUT',
        url: `/v1/library/favorites/plus-st-${i}`,
        headers: { authorization: 'Bearer plus-user' },
        payload: {
          stationName: `Plus Station ${i}`,
          streamUrl: `https://stream.example.com/plus-${i}.mp3`,
          countryCode: 'GB',
        },
      });
      expect(res.statusCode).toBe(200);
    }

    await app.close();
  });

  it('POST /v1/reports accepts guest and authenticated station reports', async () => {
    const auth = new FakeAuthProvider();
    auth.setToken('reporter-token', {
      uid: 'uid-reporter',
      email: 'reporter@example.com',
      emailVerified: true,
    });
    const reportRepo = new InMemoryReportRepo();
    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: new InMemoryUserRepo(),
      libraryRepository: new InMemoryLibraryRepo(),
      reportRepository: reportRepo,
    });

    const guestRes = await app.inject({
      method: 'POST',
      url: '/v1/reports',
      payload: {
        stationId: 'st-dead',
        stationName: 'Dead FM',
        reason: 'DEAD_STREAM',
        notes: '404 from stream host',
      },
    });
    expect(guestRes.statusCode).toBe(201);
    expect(guestRes.json().report.userId).toBeNull();

    const authedRes = await app.inject({
      method: 'POST',
      url: '/v1/reports',
      headers: { authorization: 'Bearer reporter-token' },
      payload: {
        stationId: 'st-wrong',
        stationName: 'Wrong Info FM',
        reason: 'WRONG_INFO',
      },
    });
    expect(authedRes.statusCode).toBe(201);
    expect(authedRes.json().report.userId).not.toBeNull();
    expect(reportRepo.reports).toHaveLength(2);

    await app.close();
  });
});
