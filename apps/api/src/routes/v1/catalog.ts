import type { FastifyInstance } from 'fastify';
import type { CatalogService } from '../../services/catalog-service.js';

const CATALOG_CACHE_CONTROL =
  'public, max-age=3600, stale-while-revalidate=86400';

export function registerCatalogRoutes(
  app: FastifyInstance,
  catalogService: CatalogService,
): void {
  app.get(
    '/v1/catalog/countries',
    {
      schema: {
        tags: ['Catalog'],
        summary: 'List radio countries ordered by station count',
      },
    },
    async (_request, reply) => {
      const items = await catalogService.getCountries();
      reply.header('Cache-Control', CATALOG_CACHE_CONTROL);
      return { items, total: items.length };
    },
  );

  app.get(
    '/v1/catalog/genres',
    {
      schema: {
        tags: ['Catalog'],
        summary: 'List canonical genres normalised via genre-map.json',
      },
    },
    async (_request, reply) => {
      const items = await catalogService.getGenres();
      reply.header('Cache-Control', CATALOG_CACHE_CONTROL);
      return { items, total: items.length };
    },
  );

  app.get(
    '/v1/catalog/languages',
    {
      schema: {
        tags: ['Catalog'],
        summary: 'List radio broadcast languages ordered by station count',
      },
    },
    async (_request, reply) => {
      const items = await catalogService.getLanguages();
      reply.header('Cache-Control', CATALOG_CACHE_CONTROL);
      return { items, total: items.length };
    },
  );
}
