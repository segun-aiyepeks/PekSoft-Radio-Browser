import { APP_NAME } from '@peksoft/shared';
import type { FastifyInstance } from 'fastify';

export function registerHealthRoutes(
  app: FastifyInstance,
  version: string,
): void {
  app.get(
    '/health',
    {
      config: {
        rateLimit: false,
      },
      schema: {
        tags: ['System'],
        summary: 'Service health check',
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
}
