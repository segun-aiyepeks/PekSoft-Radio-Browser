import type {
  CollectionInput,
  CollectionItemInput,
  DeltaSyncRequest,
  FavoriteInput,
  RecentInput,
  SongHistoryInput,
} from '@peksoft/shared';
import type { VerifiedIdentity } from '../auth/firebase-auth.js';
import { AppError, notFound } from '../errors/app-error.js';
import type {
  CollectionItemRecord,
  CollectionRecord,
  FavoriteRecord,
  LibraryRepository,
  RecentRecord,
  SongHistoryRecord,
} from '../repositories/library-repository.js';
import type {
  UserRepository,
  UserWithEntitlementRecord,
} from '../repositories/user-repository.js';
import { computeEntitlementView } from './user-service.js';

function parseDate(iso?: string): Date {
  return iso ? new Date(iso) : new Date();
}

export function tierLimitError(resource: string, limit: number): AppError {
  return new AppError({
    statusCode: 403,
    code: 'TIER_LIMIT_REACHED',
    message: `Free tier limit of ${limit} ${resource} reached. Upgrade to Plus for unlimited ${resource}.`,
    details: { resource, limit },
  });
}

export class LibraryService {
  constructor(
    private readonly users: UserRepository,
    private readonly library: LibraryRepository,
  ) {}

  private async resolveUser(
    identity: VerifiedIdentity,
  ): Promise<UserWithEntitlementRecord> {
    return this.users.findOrCreateByFirebaseUid(identity);
  }

  async listFavorites(identity: VerifiedIdentity): Promise<FavoriteRecord[]> {
    const user = await this.resolveUser(identity);
    return this.library.listFavorites(user.id);
  }

  async upsertFavorite(
    identity: VerifiedIdentity,
    input: FavoriteInput,
  ): Promise<{ record: FavoriteRecord; applied: boolean }> {
    const user = await this.resolveUser(identity);
    const limits = computeEntitlementView(user.entitlement).limits;
    const updatedAt = parseDate(input.updatedAt);

    if (!input.isDeleted && limits.maxFavorites !== null) {
      const existing = await this.library.findFavorite(user.id, input.stationId);
      const isNewOrReactivating = !existing || existing.isDeleted;
      if (isNewOrReactivating) {
        const count = await this.library.countActiveFavorites(user.id);
        if (count >= limits.maxFavorites) {
          throw tierLimitError('favourites', limits.maxFavorites);
        }
      }
    }

    return this.library.upsertFavoriteLww(user.id, input, updatedAt);
  }

  async deleteFavorite(
    identity: VerifiedIdentity,
    stationId: string,
    updatedAtIso?: string,
  ): Promise<void> {
    const user = await this.resolveUser(identity);
    const existing = await this.library.findFavorite(user.id, stationId);
    if (!existing) {
      return;
    }
    await this.library.upsertFavoriteLww(
      user.id,
      {
        stationId: existing.stationId,
        stationName: existing.stationName,
        streamUrl: existing.streamUrl,
        countryCode: existing.countryCode,
        faviconUrl: existing.faviconUrl,
        codec: existing.codec,
        bitrateKbps: existing.bitrateKbps,
        isDeleted: true,
      },
      parseDate(updatedAtIso),
    );
  }

  async listCollections(
    identity: VerifiedIdentity,
  ): Promise<CollectionRecord[]> {
    const user = await this.resolveUser(identity);
    return this.library.listCollections(user.id);
  }

  async upsertCollection(
    identity: VerifiedIdentity,
    input: CollectionInput,
  ): Promise<{ record: CollectionRecord; applied: boolean }> {
    const user = await this.resolveUser(identity);
    const limits = computeEntitlementView(user.entitlement).limits;
    const updatedAt = parseDate(input.updatedAt);

    if (!input.isDeleted && limits.maxCollections !== null) {
      const existing = input.id
        ? await this.library.findCollection(user.id, input.id)
        : null;
      const isNewOrReactivating = !existing || existing.isDeleted;
      if (isNewOrReactivating) {
        const count = await this.library.countActiveCollections(user.id);
        if (count >= limits.maxCollections) {
          throw tierLimitError('collections', limits.maxCollections);
        }
      }
    }

    const result = await this.library.upsertCollectionLww(
      user.id,
      input,
      updatedAt,
    );

    if (result.applied && input.items && input.items.length > 0) {
      for (const item of input.items) {
        await this.library.upsertCollectionItemLww(
          user.id,
          result.record.id,
          item,
          parseDate(item.updatedAt ?? input.updatedAt),
        );
      }
      const refreshed = await this.library.findCollection(
        user.id,
        result.record.id,
      );
      if (refreshed) {
        return { record: refreshed, applied: true };
      }
    }

    return result;
  }

  async deleteCollection(
    identity: VerifiedIdentity,
    collectionId: string,
    updatedAtIso?: string,
  ): Promise<void> {
    const user = await this.resolveUser(identity);
    const existing = await this.library.findCollection(user.id, collectionId);
    if (!existing) {
      throw notFound(`Collection ${collectionId} not found`);
    }
    await this.library.upsertCollectionLww(
      user.id,
      {
        id: existing.id,
        name: existing.name,
        description: existing.description,
        isDeleted: true,
      },
      parseDate(updatedAtIso),
    );
  }

  async upsertCollectionItem(
    identity: VerifiedIdentity,
    collectionId: string,
    input: CollectionItemInput,
  ): Promise<{ record: CollectionItemRecord; applied: boolean }> {
    const user = await this.resolveUser(identity);
    const res = await this.library.upsertCollectionItemLww(
      user.id,
      collectionId,
      input,
      parseDate(input.updatedAt),
    );
    if (!res) {
      throw notFound(`Collection ${collectionId} not found`);
    }
    return res;
  }

  async deleteCollectionItem(
    identity: VerifiedIdentity,
    collectionId: string,
    stationId: string,
    updatedAtIso?: string,
  ): Promise<void> {
    const user = await this.resolveUser(identity);
    const collection = await this.library.findCollection(user.id, collectionId);
    if (!collection) {
      throw notFound(`Collection ${collectionId} not found`);
    }
    const existing = collection.items.find((i) => i.stationId === stationId);
    if (!existing) {
      return;
    }
    await this.library.upsertCollectionItemLww(
      user.id,
      collectionId,
      {
        stationId: existing.stationId,
        stationName: existing.stationName,
        streamUrl: existing.streamUrl,
        countryCode: existing.countryCode,
        position: existing.position,
        isDeleted: true,
      },
      parseDate(updatedAtIso),
    );
  }

  async listRecents(identity: VerifiedIdentity): Promise<RecentRecord[]> {
    const user = await this.resolveUser(identity);
    const limits = computeEntitlementView(user.entitlement).limits;
    const items = await this.library.listRecents(user.id);
    return items.slice(0, limits.maxRecentlyPlayed);
  }

  async upsertRecent(
    identity: VerifiedIdentity,
    input: RecentInput,
  ): Promise<{ record: RecentRecord; applied: boolean }> {
    const user = await this.resolveUser(identity);
    const playedAt = parseDate(input.playedAt);
    const updatedAt = parseDate(input.updatedAt ?? input.playedAt);
    return this.library.upsertRecentLww(user.id, input, playedAt, updatedAt);
  }

  async listSongHistory(
    identity: VerifiedIdentity,
  ): Promise<SongHistoryRecord[]> {
    const user = await this.resolveUser(identity);
    return this.library.listSongHistory(user.id);
  }

  async addSongHistory(
    identity: VerifiedIdentity,
    input: SongHistoryInput,
  ): Promise<SongHistoryRecord> {
    const user = await this.resolveUser(identity);
    const limits = computeEntitlementView(user.entitlement).limits;
    const heardAt = parseDate(input.heardAt);
    const updatedAt = parseDate(input.updatedAt ?? input.heardAt);
    return this.library.addSongHistory(
      user.id,
      input,
      heardAt,
      updatedAt,
      limits.maxSongHistory,
    );
  }

  async deltaSync(identity: VerifiedIdentity, payload: DeltaSyncRequest) {
    const user = await this.resolveUser(identity);
    const limits = computeEntitlementView(user.entitlement).limits;
    const since = payload.since ? new Date(payload.since) : undefined;
    const serverTime = new Date().toISOString();

    const rejected: Array<{
      type: 'favorite' | 'collection';
      id: string;
      code: string;
      message: string;
    }> = [];
    let appliedCount = 0;

    for (const fav of payload.favorites) {
      if (!fav.isDeleted && limits.maxFavorites !== null) {
        const existing = await this.library.findFavorite(user.id, fav.stationId);
        if (!existing || existing.isDeleted) {
          const count = await this.library.countActiveFavorites(user.id);
          if (count >= limits.maxFavorites) {
            rejected.push({
              type: 'favorite',
              id: fav.stationId,
              code: 'TIER_LIMIT_REACHED',
              message: `Free tier limit of ${limits.maxFavorites} favourites reached`,
            });
            continue;
          }
        }
      }
      const res = await this.library.upsertFavoriteLww(
        user.id,
        fav,
        parseDate(fav.updatedAt),
      );
      if (res.applied) appliedCount++;
    }

    for (const col of payload.collections) {
      if (!col.isDeleted && limits.maxCollections !== null) {
        const existing = col.id
          ? await this.library.findCollection(user.id, col.id)
          : null;
        if (!existing || existing.isDeleted) {
          const count = await this.library.countActiveCollections(user.id);
          if (count >= limits.maxCollections) {
            rejected.push({
              type: 'collection',
              id: col.id ?? col.name,
              code: 'TIER_LIMIT_REACHED',
              message: `Free tier limit of ${limits.maxCollections} collections reached`,
            });
            continue;
          }
        }
      }
      const res = await this.library.upsertCollectionLww(
        user.id,
        col,
        parseDate(col.updatedAt),
      );
      if (res.applied) {
        appliedCount++;
        for (const item of col.items ?? []) {
          const itemRes = await this.library.upsertCollectionItemLww(
            user.id,
            res.record.id,
            item,
            parseDate(item.updatedAt ?? col.updatedAt),
          );
          if (itemRes?.applied) appliedCount++;
        }
      }
    }

    for (const recent of payload.recents) {
      const playedAt = parseDate(recent.playedAt);
      const updatedAt = parseDate(recent.updatedAt ?? recent.playedAt);
      const res = await this.library.upsertRecentLww(
        user.id,
        recent,
        playedAt,
        updatedAt,
      );
      if (res.applied) appliedCount++;
    }

    for (const song of payload.songHistory) {
      const heardAt = parseDate(song.heardAt);
      const updatedAt = parseDate(song.updatedAt ?? song.heardAt);
      await this.library.addSongHistory(
        user.id,
        song,
        heardAt,
        updatedAt,
        limits.maxSongHistory,
      );
      appliedCount++;
    }

    const [favorites, collections, recents, songHistory] = await Promise.all([
      this.library.listFavorites(user.id, since),
      this.library.listCollections(user.id, since),
      this.library.listRecents(user.id, since),
      this.library.listSongHistory(user.id, since),
    ]);

    return {
      serverTime,
      appliedCount,
      rejected,
      changes: {
        favorites,
        collections,
        recents,
        songHistory,
      },
    };
  }
}
