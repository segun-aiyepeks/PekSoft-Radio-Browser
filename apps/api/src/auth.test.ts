import { describe, expect, it } from 'vitest';
import type { AuthProvider, VerifiedIdentity } from './auth/firebase-auth.js';
import type { Env } from './config/env.js';
import { unauthorized } from './errors/app-error.js';
import type {
  UserRepository,
  UserWithEntitlementRecord,
} from './repositories/user-repository.js';
import { buildServer } from './server.js';

class MockAuthProvider implements AuthProvider {
  readonly deletedUids: string[] = [];
  private readonly validTokens = new Map<string, VerifiedIdentity>();

  registerToken(token: string, identity: VerifiedIdentity) {
    this.validTokens.set(token, identity);
  }

  async verifyIdToken(idToken: string): Promise<VerifiedIdentity> {
    const match = this.validTokens.get(idToken);
    if (!match) {
      throw unauthorized('Invalid or expired authentication token');
    }
    return match;
  }

  async deleteUser(uid: string): Promise<void> {
    this.deletedUids.push(uid);
  }
}

class InMemoryUserRepository implements UserRepository {
  readonly users = new Map<string, UserWithEntitlementRecord>();
  private nextId = 1;

  async findOrCreateByFirebaseUid(
    identity: VerifiedIdentity,
  ): Promise<UserWithEntitlementRecord> {
    const existing = this.users.get(identity.uid);
    if (existing) {
      return existing;
    }
    const now = new Date();
    const created: UserWithEntitlementRecord = {
      id: `user-uuid-${this.nextId++}`,
      firebaseUid: identity.uid,
      email: identity.email ?? null,
      displayName: identity.displayName ?? null,
      createdAt: now,
      updatedAt: now,
      entitlement: {
        tier: 'FREE',
        status: 'ACTIVE',
        source: 'NONE',
        expiresAt: null,
      },
    };
    this.users.set(identity.uid, created);
    return created;
  }

  async deleteByFirebaseUid(firebaseUid: string): Promise<boolean> {
    return this.users.delete(firebaseUid);
  }
}

function makeTestEnv(): Env {
  return {
    PORT: 4000,
    HOST: '0.0.0.0',
    NODE_ENV: 'test',
    LOG_LEVEL: 'silent',
    CORS_ORIGINS: '*',
    RATE_LIMIT_MAX: 100,
    RATE_LIMIT_WINDOW_MS: 60_000,
    APP_VERSION: '0.1.0',
  };
}

describe('Milestone 4.4 Authentication & /v1/me', () => {
  it('rejects missing or invalid Bearer tokens with 401 UNAUTHORIZED', async () => {
    const auth = new MockAuthProvider();
    const repo = new InMemoryUserRepository();
    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: repo,
    });

    const missing = await app.inject({ method: 'GET', url: '/v1/me' });
    expect(missing.statusCode).toBe(401);
    expect(missing.json().error.code).toBe('UNAUTHORIZED');

    const badScheme = await app.inject({
      method: 'GET',
      url: '/v1/me',
      headers: { authorization: 'Basic abc123' },
    });
    expect(badScheme.statusCode).toBe(401);

    const invalidToken = await app.inject({
      method: 'GET',
      url: '/v1/me',
      headers: { authorization: 'Bearer expired-token' },
    });
    expect(invalidToken.statusCode).toBe(401);

    await app.close();
  });

  it('GET /v1/me creates the user on first call and is idempotent thereafter', async () => {
    const auth = new MockAuthProvider();
    auth.registerToken('valid-token-1', {
      uid: 'fb-uid-1',
      email: 'segun@example.com',
      emailVerified: true,
      displayName: 'Segun',
    });
    const repo = new InMemoryUserRepository();

    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: repo,
    });

    const first = await app.inject({
      method: 'GET',
      url: '/v1/me',
      headers: { authorization: 'Bearer valid-token-1' },
    });
    expect(first.statusCode).toBe(200);
    const firstBody = first.json();
    expect(firstBody.user.firebaseUid).toBe('fb-uid-1');
    expect(firstBody.user.email).toBe('segun@example.com');
    expect(firstBody.entitlement.tier).toBe('FREE');
    expect(firstBody.entitlement.adsEnabled).toBe(true);
    expect(firstBody.entitlement.limits.maxFavorites).toBe(10);
    expect(repo.users.size).toBe(1);

    const second = await app.inject({
      method: 'GET',
      url: '/v1/me',
      headers: { authorization: 'Bearer valid-token-1' },
    });
    expect(second.statusCode).toBe(200);
    expect(second.json().user.id).toBe(firstBody.user.id);
    expect(repo.users.size).toBe(1);

    await app.close();
  });

  it('DELETE /v1/me deletes user data and the Firebase account', async () => {
    const auth = new MockAuthProvider();
    auth.registerToken('valid-token-2', {
      uid: 'fb-uid-delete',
      email: 'delete@example.com',
      emailVerified: true,
    });
    const repo = new InMemoryUserRepository();

    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: repo,
    });

    await app.inject({
      method: 'GET',
      url: '/v1/me',
      headers: { authorization: 'Bearer valid-token-2' },
    });
    expect(repo.users.has('fb-uid-delete')).toBe(true);

    const del = await app.inject({
      method: 'DELETE',
      url: '/v1/me',
      headers: { authorization: 'Bearer valid-token-2' },
    });
    expect(del.statusCode).toBe(204);
    expect(repo.users.has('fb-uid-delete')).toBe(false);
    expect(auth.deletedUids).toEqual(['fb-uid-delete']);

    await app.close();
  });
});
