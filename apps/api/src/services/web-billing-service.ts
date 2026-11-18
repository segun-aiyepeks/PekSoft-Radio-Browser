import {
  FEATURE_FLAGS,
  type BillingPlanPeriod,
} from '@peksoft/shared';
import type { VerifiedIdentity } from '../auth/firebase-auth.js';
import { badRequest, unauthorized } from '../errors/app-error.js';
import type { UserRepository } from '../repositories/user-repository.js';
import type { WebhookEventRepository } from '../repositories/webhook-event-repository.js';
import type {
  EntitlementService,
  EntitlementView,
} from './entitlement-service.js';
import {
  computeExpiryForPeriod,
  type PaymentProvider,
} from './payment-provider.js';

export interface WebBillingServiceOptions {
  provider: PaymentProvider;
  users: UserRepository;
  entitlementService: EntitlementService;
  webhookEvents: WebhookEventRepository;
}

interface PaystackWebhookPayload {
  event?: string;
  data?: {
    id?: string | number;
    reference?: string;
    subscription_code?: string;
    email_token?: string;
    customer?: { customer_code?: string; email?: string };
    metadata?: { userId?: string; period?: BillingPlanPeriod };
    plan?: { interval?: string; plan_code?: string };
    next_payment_date?: string;
  };
}

export class WebBillingService {
  private readonly provider: PaymentProvider;
  private readonly users: UserRepository;
  private readonly entitlementService: EntitlementService;
  private readonly webhookEvents: WebhookEventRepository;

  constructor(options: WebBillingServiceOptions) {
    this.provider = options.provider;
    this.users = options.users;
    this.entitlementService = options.entitlementService;
    this.webhookEvents = options.webhookEvents;
  }

  async initializeCheckout(
    identity: VerifiedIdentity,
    input: { period: BillingPlanPeriod; callbackUrl: string },
  ): Promise<{ authorizationUrl: string; reference: string }> {
    const user = await this.users.findOrCreateByFirebaseUid(identity);
    const email = user.email ?? identity.email;
    if (!email) {
      throw badRequest(
        'An email address is required on your account before checkout.',
      );
    }

    return this.provider.initializeSubscription({
      email,
      period: input.period,
      callbackUrl: input.callbackUrl,
      userId: user.id,
      firebaseUid: user.firebaseUid,
    });
  }

  async verifyCallback(
    identity: VerifiedIdentity,
    reference: string,
  ): Promise<{
    entitlement: EntitlementView;
    applied: boolean;
    crossPlatformEntitlements: boolean;
  }> {
    const user = await this.users.findOrCreateByFirebaseUid(identity);
    const verified = await this.provider.verifyTransaction(reference);
    if (!verified.verified) {
      throw badRequest('Transaction could not be verified as successful.');
    }

    const granted = await this.entitlementService.grantPlus({
      userId: user.id,
      source: 'paystack',
      status: 'ACTIVE',
      externalCustomerId: verified.customerCode,
      externalSubscriptionId: verified.subscriptionCode ?? verified.reference,
      expiresAt: verified.expiresAt,
    });

    return {
      entitlement: granted.entitlement,
      applied: granted.applied,
      crossPlatformEntitlements: FEATURE_FLAGS.crossPlatformEntitlements,
    };
  }

  async cancelSubscription(identity: VerifiedIdentity): Promise<{
    entitlement: EntitlementView;
    cancelled: boolean;
  }> {
    const user = await this.users.findOrCreateByFirebaseUid(identity);
    const current = await this.entitlementService.getForIdentity(identity);

    if (current.entitlement.externalSubscriptionId) {
      await this.provider.cancelSubscription({
        subscriptionCode: current.entitlement.externalSubscriptionId,
      });
    }

    const revoked = await this.entitlementService.revokePlus({
      userId: user.id,
      source: 'paystack',
      status: 'CANCELLED',
    });

    return {
      entitlement: revoked.entitlement,
      cancelled: true,
    };
  }

  async handleWebhook(params: {
    rawBody: string | Buffer;
    signature: string | undefined;
  }): Promise<{ processed: boolean; duplicate: boolean; eventType: string }> {
    if (!this.provider.verifyWebhookSignature(params.rawBody, params.signature)) {
      throw unauthorized('Invalid Paystack webhook signature');
    }

    const text =
      typeof params.rawBody === 'string'
        ? params.rawBody
        : params.rawBody.toString('utf8');
    const payload = JSON.parse(text) as PaystackWebhookPayload;
    const eventType = payload.event ?? 'unknown';
    const data = payload.data ?? {};
    const eventId =
      data.id !== undefined
        ? `${eventType}:${String(data.id)}`
        : `${eventType}:${data.reference ?? data.subscription_code ?? 'no-id'}`;

    const recorded = await this.webhookEvents.recordEvent({
      provider: 'paystack',
      eventId,
      eventType,
      payload,
    });

    if (recorded.isDuplicate) {
      return { processed: true, duplicate: true, eventType };
    }

    const userId = data.metadata?.userId;
    if (userId) {
      if (eventType === 'charge.success' || eventType === 'subscription.create') {
        const period: BillingPlanPeriod =
          data.metadata?.period === 'monthly' ||
          data.plan?.interval === 'monthly'
            ? 'monthly'
            : 'annual';
        const expiresAt = data.next_payment_date
          ? new Date(data.next_payment_date)
          : computeExpiryForPeriod(period);

        await this.entitlementService.grantPlus({
          userId,
          source: 'paystack',
          status: 'ACTIVE',
          externalCustomerId: data.customer?.customer_code ?? null,
          externalSubscriptionId:
            data.subscription_code ?? data.reference ?? null,
          expiresAt,
        });
      } else if (
        eventType === 'subscription.disable' ||
        eventType === 'subscription.not_renew'
      ) {
        await this.entitlementService.revokePlus({
          userId,
          source: 'paystack',
          status: 'CANCELLED',
          externalSubscriptionId: data.subscription_code ?? null,
        });
      } else if (eventType === 'invoice.payment_failed') {
        await this.entitlementService.revokePlus({
          userId,
          source: 'paystack',
          status: 'EXPIRED',
          externalSubscriptionId: data.subscription_code ?? null,
        });
      }
    }

    await this.webhookEvents.markProcessed('paystack', eventId);
    return { processed: true, duplicate: false, eventType };
  }
}
