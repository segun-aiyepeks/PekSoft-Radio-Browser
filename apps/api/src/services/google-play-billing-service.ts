import { timingSafeEqual } from 'node:crypto';
import {
  GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES,
  type GooglePlayVerifyPurchaseRequest,
} from '@peksoft/shared';
import { z } from 'zod';
import type { VerifiedIdentity } from '../auth/firebase-auth.js';
import type {
  GooglePlaySubscriptionVerification,
  GooglePlayVerifier,
} from '../billing/google-play-client.js';
import { AppError, unauthorized } from '../errors/app-error.js';
import type { EntitlementRepository } from '../repositories/entitlement-repository.js';
import type { UserRepository } from '../repositories/user-repository.js';
import type { WebhookEventRepository } from '../repositories/webhook-event-repository.js';
import type {
  EntitlementMutationResult,
  EntitlementService,
} from './entitlement-service.js';

export const pubSubPushEnvelopeSchema = z.object({
  message: z.object({
    data: z.string().min(1),
    messageId: z.string().min(1),
    publishTime: z.string().optional(),
  }),
  subscription: z.string().optional(),
});

export type PubSubPushEnvelope = z.infer<typeof pubSubPushEnvelopeSchema>;

const developerNotificationSchema = z.object({
  version: z.string().optional(),
  packageName: z.string().min(1),
  eventTimeMillis: z.string().optional(),
  subscriptionNotification: z
    .object({
      version: z.string().optional(),
      notificationType: z.number().int(),
      purchaseToken: z.string().min(1),
      subscriptionId: z.string().optional(),
    })
    .optional(),
  voidedPurchaseNotification: z
    .object({
      purchaseToken: z.string().min(1),
      orderId: z.string().optional(),
      productType: z.number().int().optional(),
      refundType: z.number().int().optional(),
    })
    .optional(),
  testNotification: z
    .object({
      version: z.string().optional(),
    })
    .optional(),
});

export interface WebhookHandlingResult {
  received: true;
  duplicate: boolean;
  eventType: string;
  applied: boolean;
}

function safeEqual(a: string, b: string): boolean {
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

function extractExpiryDate(
  verification: GooglePlaySubscriptionVerification,
): Date | null {
  const firstExpiry = verification.lineItems?.[0]?.expiryTime;
  if (!firstExpiry) return null;
  const parsed = new Date(firstExpiry);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

export class GooglePlayBillingService {
  constructor(
    private readonly options: {
      packageName: string;
      pubSubVerificationToken?: string;
      verifier: GooglePlayVerifier;
      users: UserRepository;
      entitlements: EntitlementRepository;
      entitlementService: EntitlementService;
      webhookEvents: WebhookEventRepository;
      now?: () => Date;
    },
  ) {}

  private get now(): () => Date {
    return this.options.now ?? (() => new Date());
  }

  /**
   * Verifies a client-submitted Google Play purchase token directly with the
   * Google Play Developer API (`purchases.subscriptionsv2.get`) and grants
   * server-side Plus entitlement if active/in-grace.
   */
  async verifyPurchase(
    identity: VerifiedIdentity,
    input: GooglePlayVerifyPurchaseRequest,
  ): Promise<EntitlementMutationResult> {
    const user = await this.options.users.findOrCreateByFirebaseUid(identity);
    if (input.packageName && input.packageName !== this.options.packageName) {
      throw new AppError({
        statusCode: 400,
        code: 'INVALID_PACKAGE_NAME',
        message: 'Purchase packageName does not match this application.',
      });
    }
    const packageName = this.options.packageName;

    const verification =
      await this.options.verifier.verifySubscriptionPurchase({
        packageName,
        purchaseToken: input.purchaseToken,
      });

    return this.applyPlayStateToUser({
      userId: user.id,
      purchaseToken: input.purchaseToken,
      verification,
    });
  }

  /**
   * Authenticates and idempotently processes a Google Cloud Pub/Sub push
   * notification from Google Play Real-Time Developer Notifications (RTDN).
   */
  async handlePubSubNotification(params: {
    rawEnvelope: unknown;
    queryToken?: string;
    headerToken?: string;
    authorizationHeader?: string;
  }): Promise<WebhookHandlingResult> {
    this.assertPubSubAuthenticity(params);

    const envelope = pubSubPushEnvelopeSchema.parse(params.rawEnvelope);
    const decodedJson = Buffer.from(envelope.message.data, 'base64').toString(
      'utf8',
    );
    let parsedPayload: unknown;
    try {
      parsedPayload = JSON.parse(decodedJson);
    } catch {
      throw new AppError({
        statusCode: 400,
        code: 'INVALID_PUBSUB_PAYLOAD',
        message: 'Pub/Sub message.data is not valid JSON.',
      });
    }

    const notification = developerNotificationSchema.parse(parsedPayload);
    const eventType = this.resolveEventType(notification);

    const { isDuplicate } = await this.options.webhookEvents.recordEvent({
      provider: 'google_play',
      eventId: envelope.message.messageId,
      eventType,
      payload: notification,
    });

    if (isDuplicate) {
      return {
        received: true,
        duplicate: true,
        eventType,
        applied: false,
      };
    }

    let applied = false;

    if (notification.voidedPurchaseNotification) {
      applied = await this.handleRefund(
        notification.voidedPurchaseNotification.purchaseToken,
      );
    } else if (notification.subscriptionNotification) {
      applied = await this.handleSubscriptionNotification({
        packageName: notification.packageName,
        notificationType: notification.subscriptionNotification.notificationType,
        purchaseToken: notification.subscriptionNotification.purchaseToken,
      });
    }

    await this.options.webhookEvents.markProcessed(
      'google_play',
      envelope.message.messageId,
      this.now(),
    );

    return {
      received: true,
      duplicate: false,
      eventType,
      applied,
    };
  }

  private assertPubSubAuthenticity(params: {
    queryToken?: string;
    headerToken?: string;
    authorizationHeader?: string;
  }): void {
    const expected = this.options.pubSubVerificationToken;
    if (!expected) {
      return;
    }

    const bearer = params.authorizationHeader?.startsWith('Bearer ')
      ? params.authorizationHeader.slice('Bearer '.length).trim()
      : undefined;
    const candidate =
      params.queryToken ?? params.headerToken ?? bearer ?? undefined;

    if (!candidate || !safeEqual(candidate, expected)) {
      throw unauthorized('Invalid Google Play Pub/Sub verification token');
    }
  }

  private resolveEventType(
    notification: z.infer<typeof developerNotificationSchema>,
  ): string {
    if (notification.testNotification) {
      return 'TEST_NOTIFICATION';
    }
    if (notification.voidedPurchaseNotification) {
      return 'VOIDED_PURCHASE_REFUND';
    }
    if (notification.subscriptionNotification) {
      const code = notification.subscriptionNotification.notificationType;
      const entry = Object.entries(
        GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES,
      ).find(([, value]) => value === code);
      return entry ? `SUBSCRIPTION_${entry[0]}` : `SUBSCRIPTION_${code}`;
    }
    return 'UNKNOWN';
  }

  private async resolveUserIdForPurchaseToken(
    purchaseToken: string,
    verification?: GooglePlaySubscriptionVerification,
  ): Promise<string | null> {
    const byToken =
      await this.options.entitlements.findByExternalSubscriptionId(
        'GOOGLE_PLAY',
        purchaseToken,
      );
    if (byToken) {
      return byToken.userId;
    }

    const obfuscatedUid =
      verification?.externalAccountIdentifiers?.obfuscatedExternalAccountId;
    if (obfuscatedUid) {
      const user = await this.options.users.findOrCreateByFirebaseUid({
        uid: obfuscatedUid,
        emailVerified: true,
      });
      return user.id;
    }

    return null;
  }

  private async handleRefund(purchaseToken: string): Promise<boolean> {
    const userId = await this.resolveUserIdForPurchaseToken(purchaseToken);
    if (!userId) return false;

    const result = await this.options.entitlementService.revokePlus({
      userId,
      source: 'google_play',
      status: 'CANCELLED',
      externalSubscriptionId: purchaseToken,
      expiresAt: this.now(),
    });
    return result.applied;
  }

  private async handleSubscriptionNotification(params: {
    packageName: string;
    notificationType: number;
    purchaseToken: string;
  }): Promise<boolean> {
    const T = GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES;

    // Immediate refund / revocation does not need an active grant lookup
    if (params.notificationType === T.REVOKED) {
      return this.handleRefund(params.purchaseToken);
    }

    const verification =
      await this.options.verifier.verifySubscriptionPurchase({
        packageName: params.packageName,
        purchaseToken: params.purchaseToken,
      });

    const userId = await this.resolveUserIdForPurchaseToken(
      params.purchaseToken,
      verification,
    );
    if (!userId) {
      return false;
    }

    // Explicit lifecycle overrides when Play RTDN signals hold/expiry/grace
    if (
      params.notificationType === T.ON_HOLD ||
      params.notificationType === T.PAUSED ||
      params.notificationType === T.EXPIRED
    ) {
      const res = await this.options.entitlementService.revokePlus({
        userId,
        source: 'google_play',
        status: 'EXPIRED',
        externalSubscriptionId: params.purchaseToken,
        expiresAt: extractExpiryDate(verification) ?? this.now(),
      });
      return res.applied;
    }

    if (params.notificationType === T.IN_GRACE_PERIOD) {
      const res = await this.options.entitlementService.grantPlus({
        userId,
        source: 'google_play',
        status: 'GRACE',
        externalSubscriptionId: params.purchaseToken,
        expiresAt: extractExpiryDate(verification),
      });
      return res.applied;
    }

    const mutation = await this.applyPlayStateToUser({
      userId,
      purchaseToken: params.purchaseToken,
      verification,
    });
    return mutation.applied;
  }

  private async applyPlayStateToUser(params: {
    userId: string;
    purchaseToken: string;
    verification: GooglePlaySubscriptionVerification;
  }): Promise<EntitlementMutationResult> {
    const expiresAt = extractExpiryDate(params.verification);
    const currentNow = this.now();

    switch (params.verification.subscriptionState) {
      case 'SUBSCRIPTION_STATE_ACTIVE':
        return this.options.entitlementService.grantPlus({
          userId: params.userId,
          source: 'google_play',
          status: 'ACTIVE',
          externalSubscriptionId: params.purchaseToken,
          expiresAt,
        });

      case 'SUBSCRIPTION_STATE_IN_GRACE_PERIOD':
        return this.options.entitlementService.grantPlus({
          userId: params.userId,
          source: 'google_play',
          status: 'GRACE',
          externalSubscriptionId: params.purchaseToken,
          expiresAt,
        });

      case 'SUBSCRIPTION_STATE_CANCELED':
        // User turned off auto-renew, but paid period may still be valid until expiresAt
        if (expiresAt && expiresAt.getTime() > currentNow.getTime()) {
          return this.options.entitlementService.grantPlus({
            userId: params.userId,
            source: 'google_play',
            status: 'ACTIVE',
            externalSubscriptionId: params.purchaseToken,
            expiresAt,
          });
        }
        return this.options.entitlementService.revokePlus({
          userId: params.userId,
          source: 'google_play',
          status: 'CANCELLED',
          externalSubscriptionId: params.purchaseToken,
          expiresAt: expiresAt ?? currentNow,
        });

      case 'SUBSCRIPTION_STATE_ON_HOLD':
      case 'SUBSCRIPTION_STATE_PAUSED':
      case 'SUBSCRIPTION_STATE_EXPIRED':
      case 'SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED':
      case 'SUBSCRIPTION_STATE_PENDING':
      case 'SUBSCRIPTION_STATE_UNSPECIFIED':
        return this.options.entitlementService.revokePlus({
          userId: params.userId,
          source: 'google_play',
          status: 'EXPIRED',
          externalSubscriptionId: params.purchaseToken,
          expiresAt: expiresAt ?? currentNow,
        });
    }
  }
}
