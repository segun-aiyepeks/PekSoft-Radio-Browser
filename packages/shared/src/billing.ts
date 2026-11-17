import { z } from 'zod';

export const GOOGLE_PLAY_PRODUCT_IDS = {
  monthly: 'plus_monthly',
  annual: 'plus_annual',
} as const;

export const googlePlayProductIdSchema = z.enum([
  GOOGLE_PLAY_PRODUCT_IDS.monthly,
  GOOGLE_PLAY_PRODUCT_IDS.annual,
]);

export type GooglePlayProductId = z.infer<typeof googlePlayProductIdSchema>;

export const googlePlayVerifyPurchaseRequestSchema = z.object({
  productId: googlePlayProductIdSchema,
  purchaseToken: z.string().trim().min(8).max(2048),
  packageName: z.string().trim().min(1).optional(),
});

export type GooglePlayVerifyPurchaseRequest = z.infer<
  typeof googlePlayVerifyPurchaseRequestSchema
>;

/**
 * Google Play Real-Time Developer Notification (RTDN) SubscriptionNotification
 * types (1..13) from:
 * https://developer.android.com/google/play/billing/rtdn-reference
 */
export const GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES = {
  RECOVERED: 1,
  RENEWED: 2,
  CANCELED: 3,
  PURCHASED: 4,
  ON_HOLD: 5,
  IN_GRACE_PERIOD: 6,
  RESTARTED: 7,
  PRICE_CHANGE_CONFIRMED: 8,
  DEFERRED: 9,
  PAUSED: 10,
  PAUSE_SCHEDULE_CHANGED: 11,
  REVOKED: 12,
  EXPIRED: 13,
} as const;

export type GooglePlaySubscriptionNotificationType =
  (typeof GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES)[keyof typeof GOOGLE_PLAY_SUBSCRIPTION_NOTIFICATION_TYPES];
