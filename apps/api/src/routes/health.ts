import { APP_NAME } from '@peksoft/shared';
import type { FastifyInstance } from 'fastify';

export interface HealthCheckOptions {
  checkDatabase?: () => Promise<boolean>;
}

export function registerHealthRoutes(
  app: FastifyInstance,
  version: string,
  options: HealthCheckOptions = {},
): void {
  app.get(
    '/health',
    {
      config: {
        rateLimit: false,
      },
      schema: {
        tags: ['System'],
        summary: 'Service liveness health check',
        response: {
          200: {
            type: 'object',
            required: ['status', 'service', 'version', 'uptimeSeconds', 'timestamp'],
            properties: {
              status: { type: 'string', enum: ['ok'] },
              service: { type: 'string' },
              version: { type: 'string' },
              uptimeSeconds: { type: 'number' },
              timestamp: { type: 'string', format: 'date-time' },
            },
          },
        },
      },
    },
    async () => {
      return {
        status: 'ok' as const,
        service: APP_NAME,
        version,
        uptimeSeconds: Math.round(process.uptime() * 100) / 100,
        timestamp: new Date().toISOString(),
      };
    },
  );

  app.get(
    '/health/ready',
    {
      config: {
        rateLimit: false,
      },
      schema: {
        tags: ['System'],
        summary: 'Service readiness probe for uptime monitors and orchestrators',
      },
    },
    async (_request, reply) => {
      let dbStatus: 'ok' | 'unconfigured' | 'error' = 'unconfigured';
      if (options.checkDatabase) {
        try {
          dbStatus = (await options.checkDatabase()) ? 'ok' : 'error';
        } catch {
          dbStatus = 'error';
        }
      }

      const healthy = dbStatus !== 'error';
      const memoryRssMb =
        Math.round((process.memoryUsage().rss / (1024 * 1024)) * 10) / 10;

      return reply.status(healthy ? 200 : 503).send({
        status: healthy ? 'ok' : 'degraded',
        service: APP_NAME,
        version,
        uptimeSeconds: Math.round(process.uptime() * 100) / 100,
        memoryRssMb,
        checks: {
          process: 'ok',
          database: dbStatus,
        },
        timestamp: new Date().toISOString(),
      });
    },
  );
}
