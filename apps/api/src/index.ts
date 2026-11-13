import { loadEnv } from './config/env.js';
import { buildServer } from './server.js';

async function main() {
  const env = loadEnv();
  const server = buildServer();

  await server.listen({ port: env.PORT, host: env.HOST });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
