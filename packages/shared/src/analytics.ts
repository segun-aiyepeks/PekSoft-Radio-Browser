import { z } from 'zod';

/**
 * Shared analytics event taxonomy from Section 11 of docs/ux-document.md,
 * used across mobile (Firebase Analytics) and web (PostHog / GA4).
 */
export const ANALYTICS_EVENTS = {
  STATION_PLAY: 'station_play',
  STATION_FAIL: 'station_fail',
  FAVORITE_ADD: 'favorite_add',
  PAYWALL_VIEW: 'paywall_view',
  PURCHASE_SUCCESS: 'purchase_success',
  FIRST_AUDIO_REACHED: 'first_audio_reached',
  AD_REWARDED_COMPLETED: 'ad_rewarded_completed',
  RESTORE_PURCHASES: 'restore_purchases',
} as const;

export const analyticsEventNameSchema = z.enum([
  ANALYTICS_EVENTS.STATION_PLAY,
  ANALYTICS_EVENTS.STATION_FAIL,
  ANALYTICS_EVENTS.FAVORITE_ADD,
  ANALYTICS_EVENTS.PAYWALL_VIEW,
  ANALYTICS_EVENTS.PURCHASE_SUCCESS,
  ANALYTICS_EVENTS.FIRST_AUDIO_REACHED,
  ANALYTICS_EVENTS.AD_REWARDED_COMPLETED,
  ANALYTICS_EVENTS.RESTORE_PURCHASES,
]);

export type AnalyticsEventName = z.infer<typeof analyticsEventNameSchema>;

/**
 * Keys that must never be sent in analytics events (no personal data).
 */
export const FORBIDDEN_ANALYTICS_PII_KEYS = [
  'email',
  'user_email',
  'name',
  'display_name',
  'displayname',
  'uid',
  'user_id',
  'userid',
  'firebase_uid',
  'phone',
  'phone_number',
  'token',
  'id_token',
  'password',
] as const;
