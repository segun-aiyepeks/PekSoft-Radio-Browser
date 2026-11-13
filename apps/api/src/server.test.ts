import { describe, expect, it } from 'vitest';
import { buildServer } from './server.js';

describe('API server', () => {
  it('responds with ok on GET /health', async () => {
    const app = buildServer();
    const res = await app.inject({ method: 'GET', url: '/health' });
    expect(res.statusCode).toBe(200);
    expect(res.json()).toEqual({
      status: 'ok',
      service: 'PekSoft Radio Browser',
    });
    await app.close();
  });
});
