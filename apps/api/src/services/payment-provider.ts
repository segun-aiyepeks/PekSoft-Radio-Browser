import crypto from 'node:crypto';
import type { BillingPlanPeriod } from '@peksoft/shared';

export interface InitializeSubscriptionInput {
  email: string;
  period: BillingPlanPeriod;
  callbackUrl: string;
  userId: string;
  firebaseUid: string;
}

export interface InitializeSubscriptionResult {
  authorizationUrl: string;
  reference: string;
}

export interface VerifyTransactionResult {
  verified: boolean;
  reference: string;
  status: string;
  amountMinor: number;
  currency: string;
  customerCode: string | null;
  subscriptionCode: string | null;
  planCode: string | null;
  period: BillingPlanPeriod;
  userId?: string;
  expiresAt: Date;
}

export interface CancelSubscriptionInput {
  subscriptionCode: string;
  emailToken?: string;
}

export interface PaymentProvider {
  readonly name: 'paystack' | 'stripe';
  initializeSubscription(
    input: InitializeSubscriptionInput,
  ): Promise<InitializeSubscriptionResult>;
  verifyTransaction(reference: string): Promise<VerifyTransactionResult>;
  verifyWebhookSignature(
    rawBody: string | Buffer,
    signature: string | undefined,
  ): boolean;
  cancelSubscription(
    input: CancelSubscriptionInput,
  ): Promise<{ cancelled: boolean }>;
}

export interface PaystackProviderConfig {
  secretKey: string;
  planMonthly?: string;
  planAnnual?: string;
  baseUrl?: string;
  fetchImpl?: typeof fetch;
}

const PLAN_AMOUNT_KOBO: Record<BillingPlanPeriod, number> = {
  monthly: 150_000, // ₦1,500
  annual: 1_200_000, // ₦12,000
};

export function computeExpiryForPeriod(
  period: BillingPlanPeriod,
  from: Date = new Date(),
): Date {
  const days = period === 'annual' ? 366 : 32;
  return new Date(from.getTime() + days * 24 * 60 * 60 * 1000);
}

export class PaystackProvider implements PaymentProvider {
  readonly name = 'paystack' as const;
  private readonly secretKey: string;
  private readonly planMonthly?: string;
  private readonly planAnnual?: string;
  private readonly baseUrl: string;
  private readonly fetchImpl: typeof fetch;

  constructor(config: PaystackProviderConfig) {
    this.secretKey = config.secretKey;
    this.planMonthly = config.planMonthly;
    this.planAnnual = config.planAnnual;
    this.baseUrl = (config.baseUrl ?? 'https://api.paystack.co').replace(
      /\/+$/,
      '',
    );
    this.fetchImpl = config.fetchImpl ?? fetch;
  }

  async initializeSubscription(
    input: InitializeSubscriptionInput,
  ): Promise<InitializeSubscriptionResult> {
    const planCode =
      input.period === 'annual' ? this.planAnnual : this.planMonthly;
    const body: Record<string, unknown> = {
      email: input.email,
      amount: PLAN_AMOUNT_KOBO[input.period],
      callback_url: input.callbackUrl,
      metadata: {
        userId: input.userId,
        firebaseUid: input.firebaseUid,
        period: input.period,
      },
    };
    if (planCode) {
      body.plan = planCode;
    }

    const res = await this.fetchImpl(`${this.baseUrl}/transaction/initialize`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!res.ok) {
      throw new Error(`Paystack initialize failed (${res.status})`);
    }

    const json = (await res.json()) as {
      status?: boolean;
      data?: { authorization_url?: string; reference?: string };
    };
    if (!json.status || !json.data?.authorization_url || !json.data?.reference) {
      throw new Error('Invalid Paystack initialize response');
    }

    return {
      authorizationUrl: json.data.authorization_url,
      reference: json.data.reference,
    };
  }

  async verifyTransaction(reference: string): Promise<VerifyTransactionResult> {
    const res = await this.fetchImpl(
      `${this.baseUrl}/transaction/verify/${encodeURIComponent(reference)}`,
      {
        headers: {
          Authorization: `Bearer ${this.secretKey}`,
        },
      },
    );

    if (!res.ok) {
      throw new Error(`Paystack verify failed (${res.status})`);
    }

    const json = (await res.json()) as {
      status?: boolean;
      data?: {
        status?: string;
        reference?: string;
        amount?: number;
        currency?: string;
        customer?: { customer_code?: string };
        plan?: string | null;
        metadata?: { userId?: string; period?: BillingPlanPeriod };
      };
    };

    const data = json.data;
    const period: BillingPlanPeriod =
      data?.metadata?.period === 'monthly' ? 'monthly' : 'annual';

    return {
      verified: Boolean(json.status && data?.status === 'success'),
      reference: data?.reference ?? reference,
      status: data?.status ?? 'unknown',
      amountMinor: data?.amount ?? 0,
      currency: data?.currency ?? 'NGN',
      customerCode: data?.customer?.customer_code ?? null,
      subscriptionCode: null,
      planCode: data?.plan ?? null,
      period,
      userId: data?.metadata?.userId,
      expiresAt: computeExpiryForPeriod(period),
    };
  }

  verifyWebhookSignature(
    rawBody: string | Buffer,
    signature: string | undefined,
  ): boolean {
    if (!signature || !this.secretKey) return false;
    const expected = crypto
      .createHmac('sha512', this.secretKey)
      .update(rawBody)
      .digest('hex');

    const a = Buffer.from(expected, 'utf8');
    const b = Buffer.from(signature.trim(), 'utf8');
    if (a.length !== b.length) return false;
    return crypto.timingSafeEqual(a, b);
  }

  async cancelSubscription(
    input: CancelSubscriptionInput,
  ): Promise<{ cancelled: boolean }> {
    if (!input.subscriptionCode || !input.emailToken) {
      return { cancelled: true };
    }

    const res = await this.fetchImpl(`${this.baseUrl}/subscription/disable`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        code: input.subscriptionCode,
        token: input.emailToken,
      }),
    });

    return { cancelled: res.ok };
  }
}

/**
 * Stripe provider stub only (Milestone 6.8). Not wired for live checkout yet.
 */
export class StripeProvider implements PaymentProvider {
  readonly name = 'stripe' as const;

  async initializeSubscription(): Promise<InitializeSubscriptionResult> {
    throw new Error('StripeProvider is a stub and is not enabled.');
  }

  async verifyTransaction(): Promise<VerifyTransactionResult> {
    throw new Error('StripeProvider is a stub and is not enabled.');
  }

  verifyWebhookSignature(): boolean {
    return false;
  }

  async cancelSubscription(): Promise<{ cancelled: boolean }> {
    throw new Error('StripeProvider is a stub and is not enabled.');
  }
}
