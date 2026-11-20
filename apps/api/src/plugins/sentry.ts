import crypto from 'node:crypto';
import type { Env } from '../config/env.js';

export interface SentryCaptureContext {
  requestId?: string;
  method?: string;
  url?: string;
  tags?: Record<string, string>;
}

export interface SentryReporter {
  readonly enabled: boolean;
  captureException(
    error: unknown,
    context?: SentryCaptureContext,
  ): Promise<void>;
}

interface ParsedDsn {
  storeUrl: string;
  publicKey: string;
}

/**
 * Parses a standard Sentry DSN (`https://<key>@<host>/<projectId>`) into the
 * Sentry Store API endpoint without requiring third-party SDK bloat.
 */
export function parseSentryDsn(dsn: string): ParsedDsn | null {
  try {
    const parsed = new URL(dsn);
    const publicKey = parsed.username;
    const projectId = parsed.pathname.replace(/^\/+/, '');
    if (!publicKey || !projectId) {
      return null;
    }
    const storeUrl = `${parsed.protocol}//${parsed.host}/api/${projectId}/store/`;
    return { storeUrl, publicKey };
  } catch {
    return null;
  }
}

/** Strips query strings (which may hold tokens/emails) from logged URLs. */
export function sanitizeUrlPath(rawUrl?: string): string | undefined {
  if (!rawUrl) return undefined;
  const qIndex = rawUrl.indexOf('?');
  return qIndex >= 0 ? rawUrl.slice(0, qIndex) : rawUrl;
}

export function createSentryReporter(
  env: Pick<Env, 'SENTRY_DSN' | 'SENTRY_ENVIRONMENT' | 'NODE_ENV' | 'APP_VERSION'>,
  fetchImpl: typeof fetch = fetch,
): SentryReporter {
  const parsed = env.SENTRY_DSN ? parseSentryDsn(env.SENTRY_DSN) : null;
  if (!parsed) {
    return {
      enabled: false,
      async captureException() {
        // No-op when SENTRY_DSN is not configured.
      },
    };
  }

  const environment = env.SENTRY_ENVIRONMENT ?? env.NODE_ENV;

  return {
    enabled: true,
    async captureException(
      error: unknown,
      context: SentryCaptureContext = {},
    ): Promise<void> {
      const err =
        error instanceof Error
          ? error
          : new Error(typeof error === 'string' ? error : 'Unknown error');

      const eventId = crypto.randomBytes(16).toString('hex');
      const payload = {
        event_id: eventId,
        timestamp: Math.floor(Date.now() / 1000),
        platform: 'node',
        level: 'error',
        environment,
        release: `peksoft-api@${env.APP_VERSION}`,
        exception: {
          values: [
            {
              type: err.name || 'Error',
              value: err.message || 'Unhandled error',
            },
          ],
        },
        tags: {
          ...(context.requestId ? { request_id: context.requestId } : {}),
          ...(context.method ? { http_method: context.method } : {}),
          ...(context.tags ?? {}),
        },
        request: context.url
          ? {
              method: context.method,
              url: sanitizeUrlPath(context.url),
            }
          : undefined,
      };

      try {
        await fetchImpl(parsed.storeUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Sentry-Auth': `Sentry sentry_version=7, sentry_client=peksoft-api/${env.APP_VERSION}, sentry_key=${parsed.publicKey}`,
          },
          body: JSON.stringify(payload),
        });
      } catch {
        // Never allow telemetry failure to crash request handling.
      }
    },
  };
}
