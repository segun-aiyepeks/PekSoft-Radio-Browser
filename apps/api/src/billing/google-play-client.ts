import { createSign } from 'node:crypto';
import { AppError } from '../errors/app-error.js';

export type GooglePlaySubscriptionState =
  | 'SUBSCRIPTION_STATE_UNSPECIFIED'
  | 'SUBSCRIPTION_STATE_PENDING'
  | 'SUBSCRIPTION_STATE_ACTIVE'
  | 'SUBSCRIPTION_STATE_PAUSED'
  | 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD'
  | 'SUBSCRIPTION_STATE_ON_HOLD'
  | 'SUBSCRIPTION_STATE_CANCELED'
  | 'SUBSCRIPTION_STATE_EXPIRED'
  | 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED';

export interface GooglePlaySubscriptionLineItem {
  productId: string;
  expiryTime: string;
  autoRenewingPlan?: {
    autoRenewEnabled?: boolean;
  };
}

export interface GooglePlaySubscriptionVerification {
  kind?: string;
  latestOrderId?: string;
  subscriptionState: GooglePlaySubscriptionState;
  acknowledgementState?:
    | 'ACKNOWLEDGEMENT_STATE_UNSPECIFIED'
    | 'ACKNOWLEDGEMENT_STATE_PENDING'
    | 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
  externalAccountIdentifiers?: {
    obfuscatedExternalAccountId?: string;
    obfuscatedExternalProfileId?: string;
  };
  lineItems?: GooglePlaySubscriptionLineItem[];
}

export interface GooglePlayVerifier {
  verifySubscriptionPurchase(params: {
    packageName: string;
    purchaseToken: string;
  }): Promise<GooglePlaySubscriptionVerification>;
}

export interface GooglePlayClientOptions {
  serviceAccountEmail: string;
  privateKey: string;
  fetchImpl?: typeof fetch;
}

function base64UrlEncode(input: string | Buffer): string {
  return Buffer.from(input)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

/**
 * Calls the Google Play Developer API (`purchases.subscriptionsv2.get`) using
 * a Google Cloud service account signed with RS256 JWT OAuth2 assertions.
 */
export class HttpGooglePlayClient implements GooglePlayVerifier {
  private cachedToken: { accessToken: string; expiresAtMs: number } | null =
    null;

  private readonly privateKey: string;
  private readonly fetchImpl: typeof fetch;

  constructor(private readonly options: GooglePlayClientOptions) {
    this.privateKey = options.privateKey.replace(/\\n/g, '\n');
    this.fetchImpl = options.fetchImpl ?? fetch;
  }

  private async getAccessToken(): Promise<string> {
    const nowMs = Date.now();
    if (this.cachedToken && this.cachedToken.expiresAtMs - 60_000 > nowMs) {
      return this.cachedToken.accessToken;
    }

    const iat = Math.floor(nowMs / 1000);
    const exp = iat + 3600;
    const header = base64UrlEncode(
      JSON.stringify({ alg: 'RS256', typ: 'JWT' }),
    );
    const payload = base64UrlEncode(
      JSON.stringify({
        iss: this.options.serviceAccountEmail,
        scope: 'https://www.googleapis.com/auth/androidpublisher',
        aud: 'https://oauth2.googleapis.com/token',
        iat,
        exp,
      }),
    );

    const signingInput = `${header}.${payload}`;
    const signer = createSign('RSA-SHA256');
    signer.update(signingInput);
    signer.end();
    const signature = base64UrlEncode(signer.sign(this.privateKey));
    const assertion = `${signingInput}.${signature}`;

    const tokenRes = await this.fetchImpl('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    });

    if (!tokenRes.ok) {
      throw new AppError({
        statusCode: 502,
        code: 'GOOGLE_PLAY_AUTH_FAILED',
        message: 'Failed to authenticate with Google Play Developer API.',
      });
    }

    const tokenJson = (await tokenRes.json()) as {
      access_token: string;
      expires_in?: number;
    };
    this.cachedToken = {
      accessToken: tokenJson.access_token,
      expiresAtMs: nowMs + (tokenJson.expires_in ?? 3600) * 1000,
    };
    return this.cachedToken.accessToken;
  }

  async verifySubscriptionPurchase(params: {
    packageName: string;
    purchaseToken: string;
  }): Promise<GooglePlaySubscriptionVerification> {
    const accessToken = await this.getAccessToken();
    const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(
      params.packageName,
    )}/purchases/subscriptionsv2/tokens/${encodeURIComponent(params.purchaseToken)}`;

    const res = await this.fetchImpl(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: 'application/json',
      },
    });

    if (!res.ok) {
      throw new AppError({
        statusCode: res.status === 404 || res.status === 410 ? 400 : 502,
        code: 'GOOGLE_PLAY_VERIFICATION_FAILED',
        message: `Google Play Developer API returned HTTP ${res.status}.`,
      });
    }

    return (await res.json()) as GooglePlaySubscriptionVerification;
  }
}
