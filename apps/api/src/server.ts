import Fastify from 'fastify';
import { APP_NAME } from '@peksoft/shared';

export function buildServer() {
  const app = Fastify({
    logger: true,
  });

  app.get('/health', async () => {
    return {
      status: 'ok',
      service: APP_NAME,
    };
  });

  return app;
}
