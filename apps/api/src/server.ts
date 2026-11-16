import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { APP_NAME } from '@peksoft/shared';
import Fastify, { type FastifyInstance } from 'fastify';
import { loadEnv, parseCorsOrigins, type Env } from './config/env.js';
import { AppError } from './errors/app-error.js';
import { registerErrorHandlers } from './plugins/error-handler.js';
import { buildLoggerOptions } from './plugins/logger.js';
import { registerHealthRoutes } from './routes/health.js';

export interface BuildServerOptions {
  env?: Env;
  logger?: boolean;
  /** Optional hook used by tests to mount ephemeral routes before ready(). */
  registerTestRoutes?: (app: FastifyInstance) => void;
}

export async function buildServer(
  options: BuildServerOptions = {},
): Promise<FastifyInstance> {
  const env = options.env ?? loadEnv();

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
      tags: [{ name: 'System', description: 'Health and service diagnostics' }],
    },
  });

  await app.register(swaggerUi, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: false,
    },
  });

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

  if (options.registerTestRoutes) {
    options.registerTestRoutes(app);
  }

  await app.ready();
  return app;
}
