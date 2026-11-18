import {
  webCheckoutInitRequestSchema,
  webCheckoutVerifyRequestSchema,
} from '@peksoft/shared';
import type { FastifyInstance, preHandlerHookHandler } from 'fastify';
import { unauthorized } from '../../errors/app-error.js';
import type { WebBillingService } from '../../services/web-billing-service.js';

export interface WebBillingRoutesOptions {
  webBillingService: WebBillingService;
  requireAuth?: preHandlerHookHandler;
}

export function registerWebBillingRoutes(
  app: FastifyInstance,
  options: WebBillingRoutesOptions,
): void {
  const { webBillingService, requireAuth } = options;

  if (requireAuth) {
    app.post(
      '/v1/billing/paystack/initialize',
      {
        preHandler: [requireAuth],
        schema: {
          tags: ['Account'],
          summary: 'Initialize a Paystack Plus subscription transaction',
        },
      },
      async (request) => {
        if (!request.authUser) throw unauthorized();
        const body = webCheckoutInitRequestSchema.parse(request.body);
        return webBillingService.initializeCheckout(request.authUser, body);
      },
    );

    app.post(
      '/v1/billing/paystack/verify',
      {
        preHandler: [requireAuth],
        schema: {
          tags: ['Account'],
          summary:
            'Verify a Paystack callback reference and grant Plus entitlement',
        },
      },
      async (request) => {
        if (!request.authUser) throw unauthorized();
        const body = webCheckoutVerifyRequestSchema.parse(request.body);
        return webBillingService.verifyCallback(
          request.authUser,
          body.reference,
        );
      },
    );

    app.post(
      '/v1/billing/paystack/cancel',
      {
        preHandler: [requireAuth],
        schema: {
          tags: ['Account'],
          summary: 'Cancel an active Paystack Plus subscription',
        },
      },
      async (request) => {
        if (!request.authUser) throw unauthorized();
        return webBillingService.cancelSubscription(request.authUser);
      },
    );
  }

  // Scoped plugin so raw JSON body is preserved for x-paystack-signature HMAC-SHA512 verification.
  app.register(async (webhookScope) => {
    webhookScope.addContentTypeParser(
      'application/json',
      { parseAs: 'buffer' },
      (_req, body, done) => {
        done(null, body);
      },
    );

    webhookScope.post(
      '/v1/webhooks/paystack',
      {
        config: { rateLimit: false },
        schema: {
          tags: ['System'],
          summary: 'Paystack webhook receiver with HMAC-SHA512 verification',
        },
      },
      async (request) => {
        const signature = request.headers['x-paystack-signature'];
        const rawBody = Buffer.isBuffer(request.body)
          ? request.body
          : Buffer.from(JSON.stringify(request.body ?? {}));

        return webBillingService.handleWebhook({
          rawBody,
          signature: typeof signature === 'string' ? signature : undefined,
        });
      },
    );
  });
}
