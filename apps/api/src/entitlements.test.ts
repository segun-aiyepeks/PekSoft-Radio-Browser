import { PLAN_FEATURE_GATES } from '@peksoft/shared';
import { randomUUID } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import type { AuthProvider, VerifiedIdentity } from './auth/firebase-auth.js';
import type { Env } from './config/env.js';
import { unauthorized } from './errors/app-error.js';
import type {
  EntitlementRecord,
  EntitlementRepository,
  UpsertEntitlementInput,
} from './repositories/entitlement-repository.js';
import type {
  UserRepository,
  UserWithEntitlementRecord,
} from './repositories/user-repository.js';
import { buildServer } from './server.js';
import { EntitlementService } from './services/entitlement-service.js';

class FakeAuthProvider implements AuthProvider {
  private readonly tokens = new Map<string, VerifiedIdentity>();
  setToken(token: string, identity: VerifiedIdentity) {
    this.tokens.set(token, identity);
  }
  async verifyIdToken(idToken: string): Promise<VerifiedIdentity> {
    const match = this.tokens.get(idToken);
    if (!match) throw unauthorized('Invalid token');
    return match;
  }
  async deleteUser(): Promise<void> {}
}

class InMemoryUserEntitlementStore
  implements UserRepository, EntitlementRepository
{
  readonly usersByUid = new Map<string, UserWithEntitlementRecord>();
  readonly entitlementsByUserId = new Map<string, EntitlementRecord>();

  async findOrCreateByFirebaseUid(
    identity: VerifiedIdentity,
  ): Promise<UserWithEntitlementRecord> {
    const existing = this.usersByUid.get(identity.uid);
    if (existing) {
      const ent = this.entitlementsByUserId.get(existing.id);
      if (ent) {
        existing.entitlement = {
          tier: ent.tier,
          status: ent.status,
          source: ent.source,
          expiresAt: ent.expiresAt,
        };
      }
      return existing;
    }

    const now = new Date();
    const userId = randomUUID();
    const ent: EntitlementRecord = {
      id: randomUUID(),
      userId,
      tier: 'FREE',
      status: 'ACTIVE',
      source: 'NONE',
      externalCustomerId: null,
      externalSubscriptionId: null,
      expiresAt: null,
      createdAt: now,
      updatedAt: now,
    };
    this.entitlementsByUserId.set(userId, ent);

    const user: UserWithEntitlementRecord = {
      id: userId,
      firebaseUid: identity.uid,
      email: identity.email ?? null,
      displayName: identity.displayName ?? null,
      createdAt: now,
      updatedAt: now,
      entitlement: {
        tier: ent.tier,
        status: ent.status,
        source: ent.source,
        expiresAt: ent.expiresAt,
      },
    };
    this.usersByUid.set(identity.uid, user);
    return user;
  }

  async deleteByFirebaseUid(firebaseUid: string): Promise<boolean> {
    return this.usersByUid.delete(firebaseUid);
  }

  async findByUserId(userId: string): Promise<EntitlementRecord | null> {
    return this.entitlementsByUserId.get(userId) ?? null;
  }

  async findByExternalSubscriptionId(
    source: EntitlementRecord['source'],
    externalSubscriptionId: string,
  ): Promise<EntitlementRecord | null> {
    for (const ent of this.entitlementsByUserId.values()) {
      if (
        ent.source === source &&
        ent.externalSubscriptionId === externalSubscriptionId
      ) {
        return ent;
      }
    }
    return null;
  }

  async upsertByUserId(
    userId: string,
    input: UpsertEntitlementInput,
  ): Promise<EntitlementRecord> {
    const existing = this.entitlementsByUserId.get(userId);
    const now = new Date();
    const updated: EntitlementRecord = {
      id: existing?.id ?? randomUUID(),
      userId,
      tier: input.tier,
      status: input.status,
      source: input.source,
      externalCustomerId: input.externalCustomerId ?? null,
      externalSubscriptionId: input.externalSubscriptionId ?? null,
      expiresAt: input.expiresAt ?? null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    };
    this.entitlementsByUserId.set(userId, updated);
    return updated;
  }
}

function makeTestEnv(): Env {
  return {
    NODE_ENV: 'test',
    HOST: '127.0.0.1',
    PORT: 4000,
    LOG_LEVEL: 'silent',
    CORS_ORIGINS: '*',
    RATE_LIMIT_MAX: 200,
    RATE_LIMIT_WINDOW_MS: 60_000,
    APP_VERSION: '0.1.0',
  };
}

describe('Milestone 5.1 — EntitlementService & GET /v1/entitlements', () => {
  it('GET /v1/entitlements returns FREE entitlement and shared Section 7 feature-gate table', async () => {
    const auth = new FakeAuthProvider();
    auth.setToken('token-free', {
      uid: 'uid-free',
      email: 'listener@example.com',
      emailVerified: true,
    });
    const store = new InMemoryUserEntitlementStore();

    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: store,
      entitlementRepository: store,
    });

    const unauth = await app.inject({
      method: 'GET',
      url: '/v1/entitlements',
    });
    expect(unauth.statusCode).toBe(401);

    const res = await app.inject({
      method: 'GET',
      url: '/v1/entitlements',
      headers: { authorization: 'Bearer token-free' },
    });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.entitlement.tier).toBe('FREE');
    expect(body.entitlement.source).toBe('none');
    expect(body.entitlement.adsEnabled).toBe(true);
    expect(body.entitlement.limits).toEqual({
      maxFavorites: 30,
      maxCollections: 2,
      maxRecentlyPlayed: 20,
      maxSongHistory: 10,
    });
    expect(body.entitlement.features).toEqual(PLAN_FEATURE_GATES.FREE);
    expect(body.plans).toEqual(PLAN_FEATURE_GATES);

    await app.close();
  });

  it('idempotently grants and revokes Plus for google_play and paystack sources', async () => {
    const store = new InMemoryUserEntitlementStore();
    const fixedNow = new Date('2026-11-16T12:00:00.000Z');
    const service = new EntitlementService(store, store, () => fixedNow);

    const user = await store.findOrCreateByFirebaseUid({
      uid: 'uid-billing-1',
      email: 'ada@example.com',
      emailVerified: true,
    });

    const expiry = new Date('2026-12-16T12:00:00.000Z');

    // First grant via google_play
    const firstGrant = await service.grantPlus({
      userId: user.id,
      source: 'google_play',
      externalCustomerId: 'gp-cust-1',
      externalSubscriptionId: 'gp-sub-token-1',
      expiresAt: expiry,
    });
    expect(firstGrant.applied).toBe(true);
    expect(firstGrant.entitlement.tier).toBe('PLUS');
    expect(firstGrant.entitlement.source).toBe('google_play');
    expect(firstGrant.entitlement.adsEnabled).toBe(false);
    expect(firstGrant.entitlement.limits.maxFavorites).toBeNull();
    expect(firstGrant.entitlement.limits.maxRecentlyPlayed).toBe(200);
    expect(firstGrant.entitlement.features.customSleepTimer).toBe(true);
    expect(firstGrant.entitlement.features.advancedFilters).toBe(true);

    // Duplicate grant with identical or earlier expiry is idempotent (applied: false)
    const duplicateGrant = await service.grantPlus({
      userId: user.id,
      source: 'google_play',
      externalCustomerId: 'gp-cust-1',
      externalSubscriptionId: 'gp-sub-token-1',
      expiresAt: new Date('2026-12-10T12:00:00.000Z'),
    });
    expect(duplicateGrant.applied).toBe(false);
    expect(duplicateGrant.entitlement.expiresAt).toBe(expiry.toISOString());

    // Revoking via a different provider (paystack) does not clobber active google_play Plus
    const mismatchedRevoke = await service.revokePlus({
      userId: user.id,
      source: 'paystack',
    });
    expect(mismatchedRevoke.applied).toBe(false);
    expect(mismatchedRevoke.entitlement.tier).toBe('PLUS');

    // Revoking via google_play downgrades to FREE and records source
    const firstRevoke = await service.revokePlus({
      userId: user.id,
      source: 'google_play',
      status: 'EXPIRED',
    });
    expect(firstRevoke.applied).toBe(true);
    expect(firstRevoke.entitlement.tier).toBe('FREE');
    expect(firstRevoke.entitlement.status).toBe('EXPIRED');
    expect(firstRevoke.entitlement.source).toBe('google_play');
    expect(firstRevoke.entitlement.adsEnabled).toBe(true);

    // Repeating the same revoke is idempotent (applied: false)
    const duplicateRevoke = await service.revokePlus({
      userId: user.id,
      source: 'google_play',
      status: 'EXPIRED',
    });
    expect(duplicateRevoke.applied).toBe(false);

    // Granting via paystack upgrades cleanly and records paystack source
    const paystackGrant = await service.grantPlus({
      userId: user.id,
      source: 'paystack',
      externalCustomerId: 'CUS_paystack_1',
      externalSubscriptionId: 'SUB_paystack_1',
      expiresAt: new Date('2027-01-16T12:00:00.000Z'),
    });
    expect(paystackGrant.applied).toBe(true);
    expect(paystackGrant.entitlement.tier).toBe('PLUS');
    expect(paystackGrant.entitlement.source).toBe('paystack');
  });

  it('automatically downgrades expired Plus entitlement to FREE view without deleting record', async () => {
    const store = new InMemoryUserEntitlementStore();
    const now = new Date('2026-11-16T12:00:00.000Z');
    const service = new EntitlementService(store, store, () => now);

    const identity: VerifiedIdentity = {
      uid: 'uid-expired',
      email: 'expired@example.com',
      emailVerified: true,
    };
    const user = await store.findOrCreateByFirebaseUid(identity);

    await service.grantPlus({
      userId: user.id,
      source: 'google_play',
      expiresAt: new Date('2026-11-15T12:00:00.000Z'), // yesterday
    });

    const current = await service.getForIdentity(identity);
    expect(current.entitlement.tier).toBe('FREE');
    expect(current.entitlement.status).toBe('EXPIRED');
    expect(current.entitlement.adsEnabled).toBe(true);
    expect(current.entitlement.limits.maxFavorites).toBe(30);
  });
});
