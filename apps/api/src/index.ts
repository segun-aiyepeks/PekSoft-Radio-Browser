import { loadEnv } from './config/env.js';
import { buildServer } from './server.js';

async function main() {
  const env = loadEnv();
  const server = await buildServer({ env });

  const shutdown = async (signal: string) => {
    server.log.info({ signal }, 'Shutting down API server');
    await server.close();
    process.exit(0);
  };

  process.on('SIGINT', () => void shutdown('SIGINT'));
  process.on('SIGTERM', () => void shutdown('SIGTERM'));

  await server.listen({ port: env.PORT, host: env.HOST });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
