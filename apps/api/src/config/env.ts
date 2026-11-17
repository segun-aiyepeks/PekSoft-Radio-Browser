import { z } from 'zod';

const emptyToUndefined = <T extends z.ZodTypeAny>(schema: T) =>
  z.preprocess(
    (val) => (typeof val === 'string' && val.trim() === '' ? undefined : val),
    schema,
  );

const envSchema = z.object({
  PORT: emptyToUndefined(
    z.coerce.number().int().positive().max(65535).default(4000),
  ),
  HOST: emptyToUndefined(z.string().min(1).default('0.0.0.0')),
  NODE_ENV: emptyToUndefined(
    z.enum(['development', 'test', 'production']).default('development'),
  ),
  LOG_LEVEL: emptyToUndefined(
    z
      .enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent'])
      .default('info'),
  ),
  CORS_ORIGINS: emptyToUndefined(z.string().default('http://localhost:3000')),
  RATE_LIMIT_MAX: emptyToUndefined(
    z.coerce.number().int().positive().default(120),
  ),
  RATE_LIMIT_WINDOW_MS: emptyToUndefined(
    z.coerce.number().int().positive().default(60_000),
  ),
  APP_VERSION: emptyToUndefined(z.string().min(1).default('0.1.0')),
  DATABASE_URL: emptyToUndefined(z.string().min(1).optional()),
  FIREBASE_PROJECT_ID: emptyToUndefined(z.string().min(1).optional()),
  FIREBASE_CLIENT_EMAIL: emptyToUndefined(z.string().email().optional()),
  FIREBASE_PRIVATE_KEY: emptyToUndefined(z.string().min(1).optional()),
  GOOGLE_PLAY_PACKAGE_NAME: emptyToUndefined(
    z.string().min(1).default('com.peksoft.radio'),
  ),
  GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL: emptyToUndefined(
    z.string().email().optional(),
  ),
  GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY: emptyToUndefined(
    z.string().min(1).optional(),
  ),
  GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN: emptyToUndefined(
    z.string().min(1).optional(),
  ),
});

export type Env = z.infer<typeof envSchema>;

export function parseCorsOrigins(raw: string): string[] | boolean {
  const trimmed = raw.trim();
  if (trimmed === '*') {
    return true;
  }
  return trimmed
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
}

export function loadEnv(raw: NodeJS.ProcessEnv = process.env): Env {
  const parsed = envSchema.safeParse(raw);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((issue) => `${issue.path.join('.') || 'env'}: ${issue.message}`)
      .join('; ');
    throw new Error(`Invalid environment configuration: ${issues}`);
  }
  return parsed.data;
}
