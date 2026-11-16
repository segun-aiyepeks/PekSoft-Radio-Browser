import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { APP_NAME } from '@peksoft/shared';
import Fastify, { type FastifyInstance } from 'fastify';
import type { CacheStore } from './cache/cache-store.js';
import { InMemoryLruCache } from './cache/in-memory-lru-cache.js';
import { loadEnv, parseCorsOrigins, type Env } from './config/env.js';
import { AppError } from './errors/app-error.js';
import { registerErrorHandlers } from './plugins/error-handler.js';
import { buildLoggerOptions } from './plugins/logger.js';
import {
  RadioBrowserClient,
  type HttpTransport,
} from './repositories/radio-browser-client.js';
import { registerHealthRoutes } from './routes/health.js';
import { registerCatalogRoutes } from './routes/v1/catalog.js';
import { registerStationRoutes } from './routes/v1/stations.js';
import { CatalogService } from './services/catalog-service.js';

export interface BuildServerOptions {
  env?: Env;
  logger?: boolean;
  enableSwaggerUi?: boolean;
  cache?: CacheStore;
  radioBrowserTransport?: HttpTransport;
  /** Optional hook used by tests to mount ephemeral routes before ready(). */
  registerTestRoutes?: (app: FastifyInstance) => void;
}

export async function buildServer(
  options: BuildServerOptions = {},
): Promise<FastifyInstance> {
  const env = options.env ?? loadEnv();
  const cache = options.cache ?? new InMemoryLruCache({ maxEntries: 500 });
  const radioBrowserClient = new RadioBrowserClient({
    appVersion: env.APP_VERSION,
    cache,
    transport: options.radioBrowserTransport,
  });
  const catalogService = new CatalogService(radioBrowserClient, cache);

  const app = Fastify({
    logger: buildLoggerOptions(env, options.logger ?? true),
  });

  registerErrorHandlers(app);

  await app.register(swagger, {
    openapi: {
      openapi: '3.1.0',
      info: {
        title: `${APP_NAME} API`,
        description:
          'Backend API for station discovery metadata, Firebase authentication, library sync, and entitlements.',
        version: env.APP_VERSION,
      },
      tags: [
        { name: 'System', description: 'Health and service diagnostics' },
        { name: 'Catalog', description: 'Countries, genres, and languages' },
        { name: 'Stations', description: 'Search, trending, and station details' },
      ],
    },
  });

  if (options.enableSwaggerUi ?? true) {
    await app.register(swaggerUi, {
      routePrefix: '/docs',
      uiConfig: {
        docExpansion: 'list',
        deepLinking: false,
      },
    });
  }

  await app.register(cors, {
    origin: parseCorsOrigins(env.CORS_ORIGINS),
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  await app.register(rateLimit, {
    global: true,
    max: env.RATE_LIMIT_MAX,
    timeWindow: env.RATE_LIMIT_WINDOW_MS,
    errorResponseBuilder: (_request, context) =>
      new AppError({
        statusCode: 429,
        code: 'RATE_LIMIT_EXCEEDED',
        message: `Rate limit exceeded. Retry in ${Math.ceil(context.ttl / 1000)}s.`,
      }),
  });

  registerHealthRoutes(app, env.APP_VERSION);
  registerCatalogRoutes(app, catalogService);
  registerStationRoutes(app, catalogService);

  if (options.registerTestRoutes) {
    options.registerTestRoutes(app);
  }

  await app.ready();
  return app;
}
