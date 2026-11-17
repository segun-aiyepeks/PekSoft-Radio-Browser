import { z } from 'zod';

/**
 * Shared application metadata schema.
 */
export const appInfoSchema = z.object({
  name: z.string().min(1),
  version: z.string().min(1),
});

export type AppInfo = z.infer<typeof appInfoSchema>;

export const APP_NAME = 'PekSoft Radio Browser';
export const USER_AGENT_PREFIX = 'PekSoftRadioBrowser';

export * from './radio.js';
export * from './sync.js';
export * from './entitlements.js';
export * from './billing.js';
export * from './analytics.js';
