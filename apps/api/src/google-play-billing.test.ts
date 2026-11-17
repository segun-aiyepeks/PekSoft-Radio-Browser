import { GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES } from '@peksoft/shared';
import { randomUUID } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import type { AuthProvider, VerifiedIdentity } from './auth/firebase-auth.js';
import type {
  GooglePlaySubscriptionVerification,
  GooglePlayVerifier,
} from './billing/google-play-client.js';
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
import type {
  WebhookEventRecord,
  WebhookEventRepository,
} from './repositories/webhook-event-repository.js';
import { buildServer } from './server.js';

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

class InMemoryBillingStore
  implements UserRepository, EntitlementRepository, WebhookEventRepository
{
  readonly usersByUid = new Map<string, UserWithEntitlementRecord>();
  readonly entitlementsByUserId = new Map<string, EntitlementRecord>();
  readonly webhookEvents = new Map<string, WebhookEventRecord>();

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

  async findByProviderEventId(
    provider: string,
    eventId: string,
  ): Promise<WebhookEventRecord | null> {
    return this.webhookEvents.get(`${provider}:${eventId}`) ?? null;
  }

  async recordEvent(input: {
    provider: string;
    eventId: string;
    eventType: string;
    payload: unknown;
  }): Promise<{ record: WebhookEventRecord; isDuplicate: boolean }> {
    const key = `${input.provider}:${input.eventId}`;
    const existing = this.webhookEvents.get(key);
    if (existing) {
      return { record: existing, isDuplicate: existing.processedAt !== null };
    }
    const created: WebhookEventRecord = {
      id: randomUUID(),
      provider: input.provider,
      eventId: input.eventId,
      eventType: input.eventType,
      payload: input.payload,
      processedAt: null,
      createdAt: new Date(),
    };
    this.webhookEvents.set(key, created);
    return { record: created, isDuplicate: false };
  }

  async markProcessed(
    provider: string,
    eventId: string,
    at: Date = new Date(),
  ): Promise<void> {
    const key = `${provider}:${eventId}`;
    const existing = this.webhookEvents.get(key);
    if (existing) {
      existing.processedAt = at;
    }
  }
}

class FakeGooglePlayVerifier implements GooglePlayVerifier {
  readonly calls: Array<{ packageName: string; purchaseToken: string }> = [];
  private readonly responses = new Map<
    string,
    GooglePlaySubscriptionVerification
  >();

  setResponse(
    purchaseToken: string,
    response: GooglePlaySubscriptionVerification,
  ) {
    this.responses.set(purchaseToken, response);
  }

  async verifySubscriptionPurchase(params: {
    packageName: string;
    purchaseToken: string;
  }): Promise<GooglePlaySubscriptionVerification> {
    this.calls.push(params);
    const match = this.responses.get(params.purchaseToken);
    if (!match) {
      throw new Error(`No fake Play response for ${params.purchaseToken}`);
    }
    return match;
  }
}

function makePubSubEnvelope(messageId: string, payload: unknown) {
  return {
    message: {
      data: Buffer.from(JSON.stringify(payload), 'utf8').toString('base64'),
      messageId,
      publishTime: '2026-11-17T09:00:00.000Z',
    },
    subscription: 'projects/peksoft-radio/subscriptions/play-rtdn-push',
  };
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
    GOOGLE_PLAY_PACKAGE_NAME: 'com.peksoft.radio',
    GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN: 'pubsub-secret-token',
  };
}

describe('Milestone 5.3 — Google Play Billing & Pub/Sub RTDN Webhooks', () => {
  it('verifies purchase tokens server-side and rejects invalid Pub/Sub tokens', async () => {
    const auth = new FakeAuthProvider();
    auth.setToken('jwt-ada', {
      uid: 'uid-ada',
      email: 'ada@example.com',
      emailVerified: true,
    });
    const store = new InMemoryBillingStore();
    const verifier = new FakeGooglePlayVerifier();
    const token = 'gp-token-annual-12345';

    verifier.setResponse(token, {
      latestOrderId: 'GPA.3311-2222-3333-44444',
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
      lineItems: [
        {
          productId: 'plus_annual',
          expiryTime: '2027-11-17T09:00:00.000Z',
          autoRenewingPlan: { autoRenewEnabled: true },
        },
      ],
    });

    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: store,
      entitlementRepository: store,
      webhookEventRepository: store,
      googlePlayVerifier: verifier,
    });

    // 1. Verify purchase via POST /v1/billing/google-play/verify
    const verifyRes = await app.inject({
      method: 'POST',
      url: '/v1/billing/google-play/verify',
      headers: { authorization: 'Bearer jwt-ada' },
      payload: {
        productId: 'plus_annual',
        purchaseToken: token,
      },
    });
    expect(verifyRes.statusCode).toBe(200);
    const verifiedBody = verifyRes.json();
    expect(verifiedBody.applied).toBe(true);
    expect(verifiedBody.entitlement.tier).toBe('PLUS');
    expect(verifiedBody.entitlement.source).toBe('google_play');
    expect(verifiedBody.entitlement.adsEnabled).toBe(false);

    // 2. Reject Pub/Sub push without valid authenticity token
    const unauthWebhook = await app.inject({
      method: 'POST',
      url: '/v1/webhooks/google-play?token=wrong-secret',
      payload: makePubSubEnvelope('msg-unauth', {
        packageName: 'com.peksoft.radio',
        testNotification: { version: '1.0' },
      }),
    });
    expect(unauthWebhook.statusCode).toBe(401);

    await app.close();
  });

  it('handles purchase, renewal, cancellation, grace period, account hold, expiry, refund, and WebhookEvent idempotency', async () => {
    const auth = new FakeAuthProvider();
    auth.setToken('jwt-tunde', {
      uid: 'uid-tunde',
      email: 'tunde@example.com',
      emailVerified: true,
    });
    const store = new InMemoryBillingStore();
    const verifier = new FakeGooglePlayVerifier();
    const purchaseToken = 'gp-token-monthly-99999';
    const T = GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES;

    const app = await buildServer({
      env: makeTestEnv(),
      logger: false,
      enableSwaggerUi: false,
      authProvider: auth,
      userRepository: store,
      entitlementRepository: store,
      webhookEventRepository: store,
      googlePlayVerifier: verifier,
    });

    // Helper to post an authentic Pub/Sub RTDN push
    const postRtdn = async (messageId: string, notificationType: number) => {
      return app.inject({
        method: 'POST',
        url: '/v1/webhooks/google-play?token=pubsub-secret-token',
        payload: makePubSubEnvelope(messageId, {
          version: '1.0',
          packageName: 'com.peksoft.radio',
          eventTimeMillis: '1794906000000',
          subscriptionNotification: {
            version: '1.0',
            notificationType,
            purchaseToken,
            subscriptionId: 'plus_monthly',
          },
        }),
      });
    };

    const getEntitlement = async () => {
      const res = await app.inject({
        method: 'GET',
        url: '/v1/entitlements',
        headers: { authorization: 'Bearer jwt-tunde' },
      });
      expect(res.statusCode).toBe(200);
      return res.json().entitlement;
    };

    // 1. PURCHASED (4) with obfuscatedExternalAccountId linking Firebase UID
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      externalAccountIdentifiers: {
        obfuscatedExternalAccountId: 'uid-tunde',
      },
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2026-12-17T09:00:00.000Z',
        },
      ],
    });
    const purchasedRes = await postRtdn('msg-purchase-1', T.PURCHASED);
    expect(purchasedRes.statusCode).toBe(200);
    expect(purchasedRes.json()).toEqual({
      received: true,
      duplicate: false,
      eventType: 'SUBSCRIPTION_PURCHASED',
      applied: true,
    });
    expect((await getEntitlement()).tier).toBe('PLUS');

    // Duplicate delivery of msg-purchase-1 must be idempotent (no second Play API call)
    const callsBeforeDup = verifier.calls.length;
    const dupRes = await postRtdn('msg-purchase-1', T.PURCHASED);
    expect(dupRes.statusCode).toBe(200);
    expect(dupRes.json()).toEqual({
      received: true,
      duplicate: true,
      eventType: 'SUBSCRIPTION_PURCHASED',
      applied: false,
    });
    expect(verifier.calls.length).toBe(callsBeforeDup);

    // 2. RENEWED (2) extends expiry
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2027-01-17T09:00:00.000Z',
        },
      ],
    });
    const renewedRes = await postRtdn('msg-renew-2', T.RENEWED);
    expect(renewedRes.statusCode).toBe(200);
    expect(renewedRes.json().applied).toBe(true);
    expect((await getEntitlement()).expiresAt).toBe('2027-01-17T09:00:00.000Z');

    // 3. CANCELED (3) preserves paid Plus until future expiryTime
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_CANCELED',
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2027-01-17T09:00:00.000Z',
          autoRenewingPlan: { autoRenewEnabled: false },
        },
      ],
    });
    const canceledRes = await postRtdn('msg-cancel-3', T.CANCELED);
    expect(canceledRes.statusCode).toBe(200);
    expect((await getEntitlement()).tier).toBe('PLUS');

    // 4. IN_GRACE_PERIOD (6) sets status GRACE while keeping Plus active
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD',
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2027-01-20T09:00:00.000Z',
        },
      ],
    });
    const graceRes = await postRtdn('msg-grace-4', T.IN_GRACE_PERIOD);
    expect(graceRes.statusCode).toBe(200);
    const graceEnt = await getEntitlement();
    expect(graceEnt.tier).toBe('PLUS');
    expect(graceEnt.status).toBe('GRACE');

    // 5. ON_HOLD (5) locks Plus extras immediately
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_ON_HOLD',
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2027-01-20T09:00:00.000Z',
        },
      ],
    });
    const holdRes = await postRtdn('msg-hold-5', T.ON_HOLD);
    expect(holdRes.statusCode).toBe(200);
    const holdEnt = await getEntitlement();
    expect(holdEnt.tier).toBe('FREE');
    expect(holdEnt.status).toBe('EXPIRED');

    // Re-activate before testing EXPIRED & refund
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2027-02-17T09:00:00.000Z',
        },
      ],
    });
    await postRtdn('msg-recover-6', T.RECOVERED);
    expect((await getEntitlement()).tier).toBe('PLUS');

    // 6. EXPIRED (13) revokes to FREE / EXPIRED
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_EXPIRED',
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2026-11-01T00:00:00.000Z',
        },
      ],
    });
    const expiredRes = await postRtdn('msg-expired-7', T.EXPIRED);
    expect(expiredRes.statusCode).toBe(200);
    expect((await getEntitlement()).tier).toBe('FREE');

    // Re-activate then test 7. REFUND (voidedPurchaseNotification)
    verifier.setResponse(purchaseToken, {
      subscriptionState: 'SUBSCRIPTION_STATE_ACTIVE',
      lineItems: [
        {
          productId: 'plus_monthly',
          expiryTime: '2027-03-17T09:00:00.000Z',
        },
      ],
    });
    await postRtdn('msg-restart-8', T.RESTARTED);
    expect((await getEntitlement()).tier).toBe('PLUS');

    const refundRes = await app.inject({
      method: 'POST',
      url: '/v1/webhooks/google-play?token=pubsub-secret-token',
      payload: makePubSubEnvelope('msg-refund-9', {
        version: '1.0',
        packageName: 'com.peksoft.radio',
        voidedPurchaseNotification: {
          purchaseToken,
          orderId: 'GPA.1234',
          productType: 1,
          refundType: 1,
        },
      }),
    });
    expect(refundRes.statusCode).toBe(200);
    expect(refundRes.json()).toEqual({
      received: true,
      duplicate: false,
      eventType: 'VOIDED_PURCHASE_REFUND',
      applied: true,
    });
    const afterRefund = await getEntitlement();
    expect(afterRefund.tier).toBe('FREE');
    expect(afterRefund.status).toBe('CANCELLED');

    await app.close();
  });
});
