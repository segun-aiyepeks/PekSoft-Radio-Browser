import { stationSearchQuerySchema } from '@peksoft/shared';
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
import type { CatalogService } from '../../services/catalog-service.js';

const trendingQuerySchema = z.object({
  limit: z.coerce.number().int().positive().max(100).default(25),
  country: z.string().trim().min(2).max(4).optional(),
  httpsOnly: z
    .union([z.boolean(), z.enum(['true', 'false'])])
    .transform((v) => v === true || v === 'true')
    .optional(),
  workingOnly: z
    .union([z.boolean(), z.enum(['true', 'false'])])
    .transform((v) => v === true || v === 'true')
    .default(true),
});

const stationIdParamsSchema = z.object({
  id: z.string().trim().min(1).max(128),
});

export function registerStationRoutes(
  app: FastifyInstance,
  catalogService: CatalogService,
): void {
  app.get(
    '/v1/stations/trending',
    {
      schema: {
        tags: ['Stations'],
        summary: 'Trending working stations by click count',
      },
    },
    async (request, reply) => {
      const query = trendingQuerySchema.parse(request.query);
      const items = await catalogService.getTrendingStations(query);
      reply.header(
        'Cache-Control',
        'public, max-age=120, stale-while-revalidate=300',
      );
      return { items, total: items.length };
    },
  );

  app.get(
    '/v1/stations/search',
    {
      schema: {
        tags: ['Stations'],
        summary: 'Search and filter normalised stations',
      },
    },
    async (request, reply) => {
      const query = stationSearchQuerySchema.parse(request.query);
      const items = await catalogService.searchStations(query);
      reply.header(
        'Cache-Control',
        'public, max-age=60, stale-while-revalidate=180',
      );
      return { items, total: items.length };
    },
  );

  app.get(
    '/v1/stations/:id',
    {
      schema: {
        tags: ['Stations'],
        summary: 'Get a single normalised station by UUID',
      },
    },
    async (request, reply) => {
      const { id } = stationIdParamsSchema.parse(request.params);
      const station = await catalogService.getStationById(id);
      reply.header(
        'Cache-Control',
        'public, max-age=300, stale-while-revalidate=600',
      );
      return { station };
    },
  );
}
