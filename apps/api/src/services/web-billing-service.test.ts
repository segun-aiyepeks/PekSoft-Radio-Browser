import crypto from 'node:crypto';
import { FEATURE_FLAGS } from '@peksoft/shared';
import { describe, expect, it, vi } from 'vitest';
import type { VerifiedIdentity } from '../auth/firebase-auth.js';
import type { EntitlementRepository } from '../repositories/entitlement-repository.js';
import type { UserRepository } from '../repositories/user-repository.js';
import type {
  WebhookEventRecord,
  WebhookEventRepository,
} from '../repositories/webhook-event-repository.js';
import { EntitlementService } from './entitlement-service.js';
import { PaystackProvider, StripeProvider } from './payment-provider.js';
import { WebBillingService } from './web-billing-service.js';

function createMocks(secretKey = 'sk_test_mock_secret') {
  const userWithEntitlement = {
    id: 'user-1',
    firebaseUid: 'fb-uid-1',
    email: 'listener@example.com',
    displayName: 'Listener',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  let entitlementState = {
    id: 'ent-1',
    userId: userWithEntitlement.id,
    tier: 'FREE' as 'FREE' | 'PLUS',
    status: 'ACTIVE' as 'ACTIVE' | 'GRACE' | 'EXPIRED' | 'CANCELLED',
    source: 'NONE' as 'NONE' | 'GOOGLE_PLAY' | 'PAYSTACK' | 'PROMO',
    externalCustomerId: null as string | null,
    externalSubscriptionId: null as string | null,
    expiresAt: null as Date | null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const users: UserRepository = {
    findOrCreateByFirebaseUid: vi.fn(async () => ({
      ...userWithEntitlement,
      entitlement: entitlementState,
    })),
    deleteByFirebaseUid: vi.fn(async () => true),
  };

  const entitlements: EntitlementRepository = {
    findByUserId: vi.fn(async () => entitlementState),
    findByExternalSubscriptionId: vi.fn(async () => entitlementState),
    upsertByUserId: vi.fn(async (_userId, input) => {
      entitlementState = {
        ...entitlementState,
        tier: input.tier,
        status: input.status,
        source: input.source,
        externalCustomerId: input.externalCustomerId ?? null,
        externalSubscriptionId: input.externalSubscriptionId ?? null,
        expiresAt: input.expiresAt ?? null,
        updatedAt: new Date(),
      };
      return entitlementState;
    }),
  };

  const seenEvents = new Map<string, WebhookEventRecord>();
  const webhookEvents: WebhookEventRepository = {
    findByProviderEventId: vi.fn(async (provider, eventId) => {
      return seenEvents.get(`${provider}:${eventId}`) ?? null;
    }),
    recordEvent: vi.fn(async (input) => {
      const key = `${input.provider}:${input.eventId}`;
      const existing = seenEvents.get(key);
      if (existing) {
        return { record: existing, isDuplicate: existing.processedAt !== null };
      }
      const record: WebhookEventRecord = {
        id: `wh-${seenEvents.size + 1}`,
        provider: input.provider,
        eventId: input.eventId,
        eventType: input.eventType,
        payload: input.payload,
        processedAt: null,
        createdAt: new Date(),
      };
      seenEvents.set(key, record);
      return { record, isDuplicate: false };
    }),
    markProcessed: vi.fn(async (provider, eventId, at = new Date()) => {
      const existing = seenEvents.get(`${provider}:${eventId}`);
      if (existing) existing.processedAt = at;
    }),
  };

  const entitlementService = new EntitlementService(users, entitlements);
  const fetchMock = vi.fn<typeof fetch>();
  const provider = new PaystackProvider({
    secretKey,
    planMonthly: 'PLN_test_monthly',
    planAnnual: 'PLN_test_annual',
    fetchImpl: fetchMock,
  });

  const service = new WebBillingService({
    provider,
    users,
    entitlementService,
    webhookEvents,
  });

  const identity: VerifiedIdentity = {
    uid: userWithEntitlement.firebaseUid,
    email: userWithEntitlement.email,
    emailVerified: true,
    name: userWithEntitlement.displayName,
  };

  return { service, provider, fetchMock, identity, entitlementService };
}

describe('WebBillingService & PaystackProvider', () => {
  it('defaults crossPlatformEntitlements feature flag to OFF', () => {
    expect(FEATURE_FLAGS.crossPlatformEntitlements).toBe(false);
  });

  it('initializes checkout, verifies callback, and grants Plus via EntitlementService', async () => {
    const { service, fetchMock, identity } = createMocks();

    fetchMock.mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          status: true,
          data: {
            authorization_url: 'https://checkout.paystack.com/test_auth_url',
            reference: 'ref_test_123',
          },
        }),
        { status: 200 },
      ),
    );

    const init = await service.initializeCheckout(identity, {
      period: 'annual',
      callbackUrl: 'https://peksoftradio.com/checkout/callback',
    });
    expect(init.authorizationUrl).toBe(
      'https://checkout.paystack.com/test_auth_url',
    );
    expect(init.reference).toBe('ref_test_123');

    fetchMock.mockResolvedValueOnce(
      new Response(
        JSON.stringify({
          status: true,
          data: {
            status: 'success',
            reference: 'ref_test_123',
            amount: 1200000,
            currency: 'NGN',
            customer: { customer_code: 'CUS_test_1' },
            metadata: { userId: 'user-1', period: 'annual' },
          },
        }),
        { status: 200 },
      ),
    );

    const verified = await service.verifyCallback(identity, 'ref_test_123');
    expect(verified.entitlement.tier).toBe('PLUS');
    expect(verified.entitlement.source).toBe('paystack');
    expect(verified.crossPlatformEntitlements).toBe(false);
  });

  it('rejects invalid webhook signatures and processes valid events idempotently', async () => {
    const secret = 'sk_test_webhook_secret';
    const { service, identity, entitlementService } = createMocks(secret);

    const payload = JSON.stringify({
      event: 'charge.success',
      data: {
        id: 999111,
        reference: 'ref_wh_1',
        customer: { customer_code: 'CUS_wh_1' },
        metadata: { userId: 'user-1', period: 'monthly' },
      },
    });

    await expect(
      service.handleWebhook({ rawBody: payload, signature: 'bad_sig' }),
    ).rejects.toThrow(/Invalid Paystack webhook signature/);

    const validSig = crypto
      .createHmac('sha512', secret)
      .update(payload)
      .digest('hex');

    const first = await service.handleWebhook({
      rawBody: payload,
      signature: validSig,
    });
    expect(first).toEqual({
      processed: true,
      duplicate: false,
      eventType: 'charge.success',
    });

    const dup = await service.handleWebhook({
      rawBody: payload,
      signature: validSig,
    });
    expect(dup).toEqual({
      processed: true,
      duplicate: true,
      eventType: 'charge.success',
    });

    const current = await entitlementService.getForIdentity(identity);
    expect(current.entitlement.tier).toBe('PLUS');
    expect(current.entitlement.source).toBe('paystack');

    // Cancel revokes entitlement
    const cancelled = await service.cancelSubscription(identity);
    expect(cancelled.cancelled).toBe(true);
    expect(cancelled.entitlement.tier).toBe('FREE');
    expect(cancelled.entitlement.status).toBe('CANCELLED');
  });

  it('provides a StripeProvider stub that is not enabled', async () => {
    const stripe = new StripeProvider();
    expect(stripe.name).toBe('stripe');
    expect(stripe.verifyWebhookSignature()).toBe(false);
    await expect(stripe.initializeSubscription()).rejects.toThrow(/stub/);
  });
});
