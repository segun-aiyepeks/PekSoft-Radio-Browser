import { z } from 'zod';

/**
 * Shared application metadata schema.
 * Domain schemas (stations, countries, genres, entitlements) will be added
 * after the Phase 0 Radio Browser API spike.
 */
export const appInfoSchema = z.object({
  name: z.string().min(1),
  version: z.string().min(1),
});

export type AppInfo = z.infer<typeof appInfoSchema>;

export const APP_NAME = 'PekSoft Radio Browser';
export const USER_AGENT_PREFIX = 'PekSoftRadioBrowser';
