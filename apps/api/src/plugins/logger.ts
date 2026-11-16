import type { FastifyRequest, FastifyServerOptions } from 'fastify';
import type { Env } from '../config/env.js';

/**
 * Builds Pino logger options that emit structured JSON logs while redacting
 * credentials and omitting personal data (IP addresses, emails, tokens).
 */
export function buildLoggerOptions(
  env: Env,
  enabled = true,
): FastifyServerOptions['logger'] {
  if (!enabled) {
    return false;
  }

  return {
    level: env.LOG_LEVEL,
    redact: {
      paths: [
        'req.headers.authorization',
        'req.headers.cookie',
        'req.headers["x-api-key"]',
        '*.password',
        '*.token',
        '*.idToken',
        '*.email',
      ],
      censor: '[REDACTED]',
    },
    serializers: {
      req(request: FastifyRequest) {
        return {
          method: request.method,
          url: request.url,
        };
      },
    },
  };
}
