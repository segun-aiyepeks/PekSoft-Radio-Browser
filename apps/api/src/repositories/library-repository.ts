import type {
  CollectionInput,
  CollectionItemInput,
  FavoriteInput,
  RecentInput,
  SongHistoryInput,
} from '@peksoft/shared';
import type { PrismaClient } from '@prisma/client';

export interface FavoriteRecord {
  id: string;
  userId: string;
  stationId: string;
  stationName: string;
  streamUrl: string;
  countryCode: string;
  faviconUrl: string | null;
  codec: string | null;
  bitrateKbps: number | null;
  isDeleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CollectionItemRecord {
  id: string;
  collectionId: string;
  stationId: string;
  stationName: string;
  streamUrl: string;
  countryCode: string;
  position: number;
  isDeleted: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CollectionRecord {
  id: string;
  userId: string;
  name: string;
  description: string | null;
  isDeleted: boolean;
  createdAt: Date;
  updatedAt: Date;
  items: CollectionItemRecord[];
}

export interface RecentRecord {
  id: string;
  userId: string;
  stationId: string;
  stationName: string;
  streamUrl: string;
  countryCode: string;
  playedAt: Date;
  updatedAt: Date;
}

export interface SongHistoryRecord {
  id: string;
  userId: string;
  stationId: string;
  stationName: string;
  trackTitle: string;
  heardAt: Date;
  updatedAt: Date;
}

export interface LibraryRepository {
  listFavorites(userId: string, since?: Date): Promise<FavoriteRecord[]>;
  findFavorite(userId: string, stationId: string): Promise<FavoriteRecord | null>;
  countActiveFavorites(userId: string): Promise<number>;
  upsertFavoriteLww(
    userId: string,
    input: FavoriteInput,
    updatedAt: Date,
  ): Promise<{ record: FavoriteRecord; applied: boolean }>;

  listCollections(userId: string, since?: Date): Promise<CollectionRecord[]>;
  findCollection(
    userId: string,
    collectionId: string,
  ): Promise<CollectionRecord | null>;
  countActiveCollections(userId: string): Promise<number>;
  upsertCollectionLww(
    userId: string,
    input: CollectionInput,
    updatedAt: Date,
  ): Promise<{ record: CollectionRecord; applied: boolean }>;
  upsertCollectionItemLww(
    userId: string,
    collectionId: string,
    input: CollectionItemInput,
    updatedAt: Date,
  ): Promise<{ record: CollectionItemRecord; applied: boolean } | null>;

  listRecents(userId: string, since?: Date): Promise<RecentRecord[]>;
  upsertRecentLww(
    userId: string,
    input: RecentInput,
    playedAt: Date,
    updatedAt: Date,
  ): Promise<{ record: RecentRecord; applied: boolean }>;

  listSongHistory(userId: string, since?: Date): Promise<SongHistoryRecord[]>;
  addSongHistory(
    userId: string,
    input: SongHistoryInput,
    heardAt: Date,
    updatedAt: Date,
    maxRetention?: number | null,
  ): Promise<SongHistoryRecord>;
}

export class PrismaLibraryRepository implements LibraryRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async listFavorites(userId: string, since?: Date): Promise<FavoriteRecord[]> {
    return this.prisma.favorite.findMany({
      where: {
        userId,
        ...(since ? { updatedAt: { gt: since } } : { isDeleted: false }),
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async findFavorite(
    userId: string,
    stationId: string,
  ): Promise<FavoriteRecord | null> {
    return this.prisma.favorite.findUnique({
      where: { userId_stationId: { userId, stationId } },
    });
  }

  async countActiveFavorites(userId: string): Promise<number> {
    return this.prisma.favorite.count({
      where: { userId, isDeleted: false },
    });
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

    const record = await this.prisma.favorite.upsert({
      where: { userId_stationId: { userId, stationId: input.stationId } },
      create: {
        userId,
        stationId: input.stationId,
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        faviconUrl: input.faviconUrl ?? null,
        codec: input.codec ?? null,
        bitrateKbps: input.bitrateKbps ?? null,
        isDeleted: input.isDeleted,
        updatedAt,
      },
      update: {
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        faviconUrl: input.faviconUrl ?? null,
        codec: input.codec ?? null,
        bitrateKbps: input.bitrateKbps ?? null,
        isDeleted: input.isDeleted,
        updatedAt,
      },
    });
    return { record, applied: true };
  }

  async listCollections(
    userId: string,
    since?: Date,
  ): Promise<CollectionRecord[]> {
    return this.prisma.collection.findMany({
      where: {
        userId,
        ...(since ? { updatedAt: { gt: since } } : { isDeleted: false }),
      },
      include: {
        items: {
          where: since ? { updatedAt: { gt: since } } : { isDeleted: false },
          orderBy: { position: 'asc' },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });
  }

  async findCollection(
    userId: string,
    collectionId: string,
  ): Promise<CollectionRecord | null> {
    return this.prisma.collection.findFirst({
      where: { id: collectionId, userId },
      include: { items: { orderBy: { position: 'asc' } } },
    });
  }

  async countActiveCollections(userId: string): Promise<number> {
    return this.prisma.collection.count({
      where: { userId, isDeleted: false },
    });
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

    const record = existing
      ? await this.prisma.collection.update({
          where: { id: existing.id },
          data: {
            name: input.name,
            description: input.description ?? null,
            isDeleted: input.isDeleted,
            updatedAt,
          },
          include: { items: { orderBy: { position: 'asc' } } },
        })
      : await this.prisma.collection.create({
          data: {
            ...(input.id ? { id: input.id } : {}),
            userId,
            name: input.name,
            description: input.description ?? null,
            isDeleted: input.isDeleted,
            updatedAt,
          },
          include: { items: { orderBy: { position: 'asc' } } },
        });

    return { record, applied: true };
  }

  async upsertCollectionItemLww(
    userId: string,
    collectionId: string,
    input: CollectionItemInput,
    updatedAt: Date,
  ): Promise<{ record: CollectionItemRecord; applied: boolean } | null> {
    const collection = await this.findCollection(userId, collectionId);
    if (!collection) {
      return null;
    }

    const existing = await this.prisma.collectionItem.findUnique({
      where: {
        collectionId_stationId: { collectionId, stationId: input.stationId },
      },
    });
    if (existing && existing.updatedAt.getTime() > updatedAt.getTime()) {
      return { record: existing, applied: false };
    }

    const record = await this.prisma.collectionItem.upsert({
      where: {
        collectionId_stationId: { collectionId, stationId: input.stationId },
      },
      create: {
        collectionId,
        stationId: input.stationId,
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        position: input.position,
        isDeleted: input.isDeleted,
        updatedAt,
      },
      update: {
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        position: input.position,
        isDeleted: input.isDeleted,
        updatedAt,
      },
    });

    await this.prisma.collection.update({
      where: { id: collectionId },
      data: { updatedAt },
    });

    return { record, applied: true };
  }

  async listRecents(userId: string, since?: Date): Promise<RecentRecord[]> {
    return this.prisma.recent.findMany({
      where: {
        userId,
        ...(since ? { updatedAt: { gt: since } } : {}),
      },
      orderBy: { playedAt: 'desc' },
      take: 100,
    });
  }

  async upsertRecentLww(
    userId: string,
    input: RecentInput,
    playedAt: Date,
    updatedAt: Date,
  ): Promise<{ record: RecentRecord; applied: boolean }> {
    const existing = await this.prisma.recent.findUnique({
      where: { userId_stationId: { userId, stationId: input.stationId } },
    });
    if (existing && existing.updatedAt.getTime() > updatedAt.getTime()) {
      return { record: existing, applied: false };
    }

    const record = await this.prisma.recent.upsert({
      where: { userId_stationId: { userId, stationId: input.stationId } },
      create: {
        userId,
        stationId: input.stationId,
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        playedAt,
        updatedAt,
      },
      update: {
        stationName: input.stationName,
        streamUrl: input.streamUrl,
        countryCode: input.countryCode,
        playedAt,
        updatedAt,
      },
    });
    return { record, applied: true };
  }

  async listSongHistory(
    userId: string,
    since?: Date,
  ): Promise<SongHistoryRecord[]> {
    return this.prisma.songHistory.findMany({
      where: {
        userId,
        ...(since ? { updatedAt: { gt: since } } : {}),
      },
      orderBy: { heardAt: 'desc' },
      take: 100,
    });
  }

  async addSongHistory(
    userId: string,
    input: SongHistoryInput,
    heardAt: Date,
    updatedAt: Date,
    maxRetention?: number | null,
  ): Promise<SongHistoryRecord> {
    const created = await this.prisma.songHistory.create({
      data: {
        userId,
        stationId: input.stationId,
        stationName: input.stationName,
        trackTitle: input.trackTitle,
        heardAt,
        updatedAt,
      },
    });

    if (maxRetention && maxRetention > 0) {
      const overflow = await this.prisma.songHistory.findMany({
        where: { userId },
        orderBy: { heardAt: 'desc' },
        skip: maxRetention,
        select: { id: true },
      });
      if (overflow.length > 0) {
        await this.prisma.songHistory.deleteMany({
          where: { id: { in: overflow.map((o) => o.id) } },
        });
      }
    }

    return created;
  }
}
