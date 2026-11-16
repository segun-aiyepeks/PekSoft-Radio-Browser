import { z } from 'zod';

export const isoDateSchema = z.string().datetime({ offset: true });

export const favoriteInputSchema = z.object({
  stationId: z.string().trim().min(1).max(128),
  stationName: z.string().trim().min(1).max(200),
  streamUrl: z.string().url().max(1000),
  countryCode: z.string().trim().max(8).default(''),
  faviconUrl: z.string().url().max(1000).nullable().optional(),
  codec: z.string().trim().max(32).nullable().optional(),
  bitrateKbps: z.number().int().nonnegative().nullable().optional(),
  isDeleted: z.boolean().default(false),
  updatedAt: isoDateSchema.optional(),
});
export type FavoriteInput = z.infer<typeof favoriteInputSchema>;

export const collectionItemInputSchema = z.object({
  stationId: z.string().trim().min(1).max(128),
  stationName: z.string().trim().min(1).max(200),
  streamUrl: z.string().url().max(1000),
  countryCode: z.string().trim().max(8).default(''),
  position: z.number().int().nonnegative().default(0),
  isDeleted: z.boolean().default(false),
  updatedAt: isoDateSchema.optional(),
});
export type CollectionItemInput = z.infer<typeof collectionItemInputSchema>;

export const collectionInputSchema = z.object({
  id: z.string().uuid().optional(),
  name: z.string().trim().min(1).max(120),
  description: z.string().trim().max(500).nullable().optional(),
  isDeleted: z.boolean().default(false),
  updatedAt: isoDateSchema.optional(),
  items: z.array(collectionItemInputSchema).max(200).optional(),
});
export type CollectionInput = z.infer<typeof collectionInputSchema>;

export const recentInputSchema = z.object({
  stationId: z.string().trim().min(1).max(128),
  stationName: z.string().trim().min(1).max(200),
  streamUrl: z.string().url().max(1000),
  countryCode: z.string().trim().max(8).default(''),
  playedAt: isoDateSchema.optional(),
  updatedAt: isoDateSchema.optional(),
});
export type RecentInput = z.infer<typeof recentInputSchema>;

export const songHistoryInputSchema = z.object({
  stationId: z.string().trim().min(1).max(128),
  stationName: z.string().trim().min(1).max(200),
  trackTitle: z.string().trim().min(1).max(300),
  heardAt: isoDateSchema.optional(),
  updatedAt: isoDateSchema.optional(),
});
export type SongHistoryInput = z.infer<typeof songHistoryInputSchema>;

export const deltaSyncRequestSchema = z.object({
  since: isoDateSchema.optional(),
  favorites: z.array(favoriteInputSchema).max(200).default([]),
  collections: z.array(collectionInputSchema).max(50).default([]),
  recents: z.array(recentInputSchema).max(100).default([]),
  songHistory: z.array(songHistoryInputSchema).max(100).default([]),
});
export type DeltaSyncRequest = z.infer<typeof deltaSyncRequestSchema>;

export const stationReportInputSchema = z.object({
  stationId: z.string().trim().min(1).max(128),
  stationName: z.string().trim().min(1).max(200),
  reason: z.enum(['DEAD_STREAM', 'WRONG_INFO', 'OFFENSIVE', 'OTHER']),
  notes: z.string().trim().max(1000).optional(),
});
export type StationReportInput = z.infer<typeof stationReportInputSchema>;
