import {
  collectionInputSchema,
  collectionItemInputSchema,
  deltaSyncRequestSchema,
  favoriteInputSchema,
  isoDateSchema,
  recentInputSchema,
  songHistoryInputSchema,
} from '@peksoft/shared';
import type { FastifyInstance, preHandlerHookHandler } from 'fastify';
import { z } from 'zod';
import { unauthorized } from '../../errors/app-error.js';
import type { LibraryService } from '../../services/library-service.js';

const stationIdParams = z.object({
  stationId: z.string().trim().min(1).max(128),
});

const collectionIdParams = z.object({
  collectionId: z.string().uuid(),
});

const collectionItemParams = z.object({
  collectionId: z.string().uuid(),
  stationId: z.string().trim().min(1).max(128),
});

const updatedAtQuerySchema = z.object({
  updatedAt: isoDateSchema.optional(),
});

export function registerLibraryRoutes(
  app: FastifyInstance,
  options: {
    requireAuth: preHandlerHookHandler;
    libraryService: LibraryService;
  },
): void {
  const { requireAuth, libraryService } = options;

  app.get(
    '/v1/library/favorites',
    {
      preHandler: requireAuth,
      schema: { tags: ['Library'], summary: 'List active user favourites' },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const items = await libraryService.listFavorites(request.authUser);
      return { items };
    },
  );

  app.put(
    '/v1/library/favorites/:stationId',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Upsert a favourite station (last-write-wins)',
      },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const { stationId } = stationIdParams.parse(request.params);
      const body = favoriteInputSchema.parse({
        ...(request.body as Record<string, unknown>),
        stationId,
      });
      return libraryService.upsertFavorite(request.authUser, body);
    },
  );

  app.delete(
    '/v1/library/favorites/:stationId',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Soft-delete a favourite station (last-write-wins)',
      },
    },
    async (request, reply) => {
      if (!request.authUser) throw unauthorized();
      const { stationId } = stationIdParams.parse(request.params);
      const { updatedAt } = updatedAtQuerySchema.parse(request.query);
      await libraryService.deleteFavorite(request.authUser, stationId, updatedAt);
      return reply.status(204).send();
    },
  );

  app.get(
    '/v1/library/collections',
    {
      preHandler: requireAuth,
      schema: { tags: ['Library'], summary: 'List user collections and items' },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const items = await libraryService.listCollections(request.authUser);
      return { items };
    },
  );

  app.post(
    '/v1/library/collections',
    {
      preHandler: requireAuth,
      schema: { tags: ['Library'], summary: 'Create a collection' },
    },
    async (request, reply) => {
      if (!request.authUser) throw unauthorized();
      const body = collectionInputSchema.parse(request.body);
      const result = await libraryService.upsertCollection(
        request.authUser,
        body,
      );
      return reply.status(201).send(result);
    },
  );

  app.patch(
    '/v1/library/collections/:collectionId',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Update a collection (last-write-wins)',
      },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const { collectionId } = collectionIdParams.parse(request.params);
      const body = collectionInputSchema.parse({
        ...(request.body as Record<string, unknown>),
        id: collectionId,
      });
      return libraryService.upsertCollection(request.authUser, body);
    },
  );

  app.delete(
    '/v1/library/collections/:collectionId',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Soft-delete a collection (last-write-wins)',
      },
    },
    async (request, reply) => {
      if (!request.authUser) throw unauthorized();
      const { collectionId } = collectionIdParams.parse(request.params);
      const { updatedAt } = updatedAtQuerySchema.parse(request.query);
      await libraryService.deleteCollection(
        request.authUser,
        collectionId,
        updatedAt,
      );
      return reply.status(204).send();
    },
  );

  app.put(
    '/v1/library/collections/:collectionId/items/:stationId',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Upsert an item inside a collection (last-write-wins)',
      },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const { collectionId, stationId } = collectionItemParams.parse(
        request.params,
      );
      const body = collectionItemInputSchema.parse({
        ...(request.body as Record<string, unknown>),
        stationId,
      });
      return libraryService.upsertCollectionItem(
        request.authUser,
        collectionId,
        body,
      );
    },
  );

  app.delete(
    '/v1/library/collections/:collectionId/items/:stationId',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Soft-delete an item from a collection',
      },
    },
    async (request, reply) => {
      if (!request.authUser) throw unauthorized();
      const { collectionId, stationId } = collectionItemParams.parse(
        request.params,
      );
      const { updatedAt } = updatedAtQuerySchema.parse(request.query);
      await libraryService.deleteCollectionItem(
        request.authUser,
        collectionId,
        stationId,
        updatedAt,
      );
      return reply.status(204).send();
    },
  );

  app.get(
    '/v1/library/recents',
    {
      preHandler: requireAuth,
      schema: { tags: ['Library'], summary: 'List recently played stations' },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const items = await libraryService.listRecents(request.authUser);
      return { items };
    },
  );

  app.put(
    '/v1/library/recents/:stationId',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Record or update a recent station play',
      },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const { stationId } = stationIdParams.parse(request.params);
      const body = recentInputSchema.parse({
        ...(request.body as Record<string, unknown>),
        stationId,
      });
      return libraryService.upsertRecent(request.authUser, body);
    },
  );

  app.get(
    '/v1/library/song-history',
    {
      preHandler: requireAuth,
      schema: { tags: ['Library'], summary: 'List recognised song history' },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const items = await libraryService.listSongHistory(request.authUser);
      return { items };
    },
  );

  app.post(
    '/v1/library/song-history',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Library'],
        summary: 'Record a recognised ICY track title',
      },
    },
    async (request, reply) => {
      if (!request.authUser) throw unauthorized();
      const body = songHistoryInputSchema.parse(request.body);
      const record = await libraryService.addSongHistory(
        request.authUser,
        body,
      );
      return reply.status(201).send({ record });
    },
  );

  app.post(
    '/v1/sync',
    {
      preHandler: requireAuth,
      schema: {
        tags: ['Sync'],
        summary: 'Delta-sync favourites, collections, recents, and song history',
      },
    },
    async (request) => {
      if (!request.authUser) throw unauthorized();
      const payload = deltaSyncRequestSchema.parse(request.body ?? {});
      return libraryService.deltaSync(request.authUser, payload);
    },
  );
}
