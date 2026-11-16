import { describe, expect, it } from 'vitest';
import { z } from 'zod';
import { loadEnv, type Env } from './config/env.js';
import { badRequest } from './errors/app-error.js';
import { buildServer } from './server.js';

function makeTestEnv(overrides: Partial<Env> = {}): Env {
  return {
    PORT: 4000,
    HOST: '0.0.0.0',
    NODE_ENV: 'test',
    LOG_LEVEL: 'silent',
    CORS_ORIGINS: 'https://radio.peksoft.com',
    RATE_LIMIT_MAX: 10,
    RATE_LIMIT_WINDOW_MS: 60_000,
    APP_VERSION: '0.1.0',
    ...overrides,
  };
}

describe('Milestone 4.1 API scaffold', () => {
  it('validates environment variables with Zod', () => {
    const valid = loadEnv({ PORT: '4500', NODE_ENV: 'production' });
    expect(valid.PORT).toBe(4500);
    expect(valid.NODE_ENV).toBe('production');

    expect(() => loadEnv({ PORT: 'not-a-number' })).toThrow(
      /Invalid environment configuration/,
    );
  });

  it('responds with ok and metadata on GET /health', async () => {
    const app = await buildServer({ env: makeTestEnv(), logger: false });
    const res = await app.inject({ method: 'GET', url: '/health' });

    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.status).toBe('ok');
    expect(body.service).toBe('PekSoft Radio Browser');
    expect(body.version).toBe('0.1.0');
    expect(typeof body.uptimeSeconds).toBe('number');
    expect(typeof body.timestamp).toBe('string');

    await app.close();
  }, 15_000);

  it('serves OpenAPI 3.1 JSON spec and Swagger UI', async () => {
    const app = await buildServer({ env: makeTestEnv(), logger: false });

    const specRes = await app.inject({ method: 'GET', url: '/docs/json' });
    expect(specRes.statusCode).toBe(200);
    const spec = specRes.json();
    expect(spec.openapi).toBe('3.1.0');
    expect(spec.paths['/health']).toBeDefined();

    const uiRes = await app.inject({ method: 'GET', url: '/docs' });
    expect([200, 302]).toContain(uiRes.statusCode);

    await app.close();
  });

  it('sets CORS headers only for allowed origins', async () => {
    const app = await buildServer({ env: makeTestEnv(), logger: false });

    const allowed = await app.inject({
      method: 'GET',
      url: '/health',
      headers: { origin: 'https://radio.peksoft.com' },
    });
    expect(allowed.headers['access-control-allow-origin']).toBe(
      'https://radio.peksoft.com',
    );

    const disallowed = await app.inject({
      method: 'GET',
      url: '/health',
      headers: { origin: 'https://evil.example.com' },
    });
    expect(disallowed.headers['access-control-allow-origin']).toBeUndefined();

    await app.close();
  });

  it('enforces rate limiting while exempting /health', async () => {
    const app = await buildServer({
      env: makeTestEnv({ RATE_LIMIT_MAX: 2 }),
      logger: false,
      registerTestRoutes: (server) => {
        server.get('/ping', async () => ({ pong: true }));
      },
    });

    expect((await app.inject({ method: 'GET', url: '/ping' })).statusCode).toBe(
      200,
    );
    expect((await app.inject({ method: 'GET', url: '/ping' })).statusCode).toBe(
      200,
    );

    const limited = await app.inject({ method: 'GET', url: '/ping' });
    expect(limited.statusCode).toBe(429);
    expect(limited.json().error.code).toBe('RATE_LIMIT_EXCEEDED');

    // /health remains exempt so load balancers never get rate-limited
    const health = await app.inject({ method: 'GET', url: '/health' });
    expect(health.statusCode).toBe(200);

    await app.close();
  });

  it('formats AppError, ZodError, unknown 500, and 404 through central error handler', async () => {
    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      registerTestRoutes: (server) => {
        server.get('/boom-app', async () => {
          throw badRequest('Invalid station filter', { field: 'country' });
        });
        server.get('/boom-zod', async () => {
          z.object({ limit: z.number().int().positive() }).parse({
            limit: -5,
          });
        });
        server.get('/boom-500', async () => {
          throw new Error('sensitive internal stack detail');
        });
      },
    });

    const appErr = await app.inject({ method: 'GET', url: '/boom-app' });
    expect(appErr.statusCode).toBe(400);
    expect(appErr.json().error.code).toBe('BAD_REQUEST');
    expect(appErr.json().error.message).toBe('Invalid station filter');

    const zodErr = await app.inject({ method: 'GET', url: '/boom-zod' });
    expect(zodErr.statusCode).toBe(400);
    expect(zodErr.json().error.code).toBe('VALIDATION_ERROR');

    const internalErr = await app.inject({ method: 'GET', url: '/boom-500' });
    expect(internalErr.statusCode).toBe(500);
    expect(internalErr.json().error.code).toBe('INTERNAL_ERROR');
    expect(internalErr.json().error.message).toBe('An unexpected error occurred');

    const missing = await app.inject({ method: 'GET', url: '/does-not-exist' });
    expect(missing.statusCode).toBe(404);
    expect(missing.json().error.code).toBe('NOT_FOUND');

    await app.close();
  });
});
