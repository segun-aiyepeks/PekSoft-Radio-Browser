import Fastify from 'fastify';
import { APP_NAME } from '@peksoft/shared';

export function buildServer(options: { logger?: boolean } = {}) {
  const app = Fastify({
    logger: options.logger ?? true,
  });

  app.get('/health', async () => {
    return {
      status: 'ok',
      service: APP_NAME,
    };
  });

  return app;
}
