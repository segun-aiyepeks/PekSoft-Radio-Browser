import { googlePlayVerifyPurchaseRequestSchema } from '@peksoft/shared';
import type { FastifyInstance, preHandlerHookHandler } from 'fastify';
import { z } from 'zod';
import { unauthorized } from '../../errors/app-error.js';
import type { GooglePlayBillingService } from '../../services/google-play-billing-service.js';

const pubSubQuerySchema = z.object({
  token: z.string().optional(),
});

export interface BillingRoutesOptions {
  googlePlayBillingService: GooglePlayBillingService;
  requireAuth?: preHandlerHookHandler;
}

export function registerBillingRoutes(
  app: FastifyInstance,
  options: BillingRoutesOptions,
): void {
  const { googlePlayBillingService, requireAuth } = options;

  if (requireAuth) {
    app.post(
      '/v1/billing/google-play/verify',
      {
        preHandler: [requireAuth],
        schema: {
          tags: ['Account'],
          summary:
            'Verify a Google Play subscription purchase token server-side and grant Plus entitlement',
        },
      },
      async (request) => {
        if (!request.authUser) {
          throw unauthorized();
        }
        const body = googlePlayVerifyPurchaseRequestSchema.parse(request.body);
        return googlePlayBillingService.verifyPurchase(request.authUser, body);
      },
    );
  }

  app.post(
    '/v1/webhooks/google-play',
    {
      config: {
        rateLimit: false,
      },
      schema: {
        tags: ['System'],
        summary:
          'Google Play Real-Time Developer Notifications (Pub/Sub push webhook)',
      },
    },
    async (request) => {
      const query = pubSubQuerySchema.parse(request.query);
      const headerToken = request.headers['x-goog-pubsub-token'];
      const authHeader = request.headers.authorization;

      return googlePlayBillingService.handlePubSubNotification({
        rawEnvelope: request.body,
        queryToken: query.token,
        headerToken: typeof headerToken === 'string' ? headerToken : undefined,
        authorizationHeader:
          typeof authHeader === 'string' ? authHeader : undefined,
      });
    },
  );
}
