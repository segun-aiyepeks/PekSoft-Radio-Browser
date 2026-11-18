import type { BillingPlanPeriod } from '@peksoft/shared';
import { getApiBaseUrl } from '@/lib/api-client';

export interface InitializeCheckoutResponse {
  authorizationUrl: string;
  reference: string;
}

export interface VerifyCheckoutResponse {
  entitlement: {
    tier: 'FREE' | 'PLUS';
    status: string;
    source: string;
    expiresAt: string | null;
  };
  applied: boolean;
  crossPlatformEntitlements: boolean;
}

export async function initializePaystackCheckout(
  token: string,
  params: { period: BillingPlanPeriod; callbackUrl: string },
): Promise<InitializeCheckoutResponse> {
  const res = await fetch(`${getApiBaseUrl()}/v1/billing/paystack/initialize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(params),
  });
  if (!res.ok) {
    throw new Error('Could not initialize Paystack checkout.');
  }
  return (await res.json()) as InitializeCheckoutResponse;
}

export async function verifyPaystackCallback(
  token: string,
  reference: string,
): Promise<VerifyCheckoutResponse> {
  const res = await fetch(`${getApiBaseUrl()}/v1/billing/paystack/verify`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ reference }),
  });
  if (!res.ok) {
    throw new Error('Could not verify Paystack payment.');
  }
  return (await res.json()) as VerifyCheckoutResponse;
}

export async function cancelPaystackSubscription(
  token: string,
): Promise<{ cancelled: boolean }> {
  const res = await fetch(`${getApiBaseUrl()}/v1/billing/paystack/cancel`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({}),
  });
  if (!res.ok) {
    throw new Error('Could not cancel subscription.');
  }
  return (await res.json()) as { cancelled: boolean };
}
