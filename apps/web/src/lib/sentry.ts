'use client';

interface ParsedDsn {
  storeUrl: string;
  publicKey: string;
}

export function parseWebSentryDsn(dsn: string): ParsedDsn | null {
  try {
    const parsed = new URL(dsn);
    const publicKey = parsed.username;
    const projectId = parsed.pathname.replace(/^\/+/, '');
    if (!publicKey || !projectId) return null;
    return {
      storeUrl: `${parsed.protocol}//${parsed.host}/api/${projectId}/store/`,
      publicKey,
    };
  } catch {
    return null;
  }
}

/**
 * Sends a PII-free error report to Sentry when `NEXT_PUBLIC_SENTRY_DSN` is set.
 * Safe no-op in local dev or when DSN is omitted.
 */
export async function captureWebException(
  error: unknown,
  context?: { route?: string; digest?: string },
): Promise<void> {
  const dsn = process.env.NEXT_PUBLIC_SENTRY_DSN;
  if (!dsn) return;
  const parsed = parseWebSentryDsn(dsn);
  if (!parsed) return;

  const err =
    error instanceof Error
      ? error
      : new Error(typeof error === 'string' ? error : 'Unknown web error');

  const payload = {
    timestamp: Math.floor(Date.now() / 1000),
    platform: 'javascript',
    level: 'error',
    environment: process.env.NEXT_PUBLIC_SENTRY_ENVIRONMENT || 'production',
    exception: {
      values: [
        {
          type: err.name || 'Error',
          value: err.message || 'Unhandled client error',
        },
      ],
    },
    tags: {
      ...(context?.route ? { route: context.route } : {}),
      ...(context?.digest ? { next_digest: context.digest } : {}),
    },
  };

  try {
    await fetch(parsed.storeUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Sentry-Auth': `Sentry sentry_version=7, sentry_client=peksoft-web/1.0.0, sentry_key=${parsed.publicKey}`,
      },
      body: JSON.stringify(payload),
      keepalive: true,
    });
  } catch {
    // Ignore telemetry network errors.
  }
}
