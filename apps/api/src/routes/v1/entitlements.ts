import type { FastifyInstance, preHandlerHookHandler } from 'fastify';
import { unauthorized } from '../../errors/app-error.js';
import type { EntitlementService } from '../../services/entitlement-service.js';

export interface EntitlementRoutesOptions {
  requireAuth: preHandlerHookHandler;
  entitlementService: EntitlementService;
}

export function registerEntitlementRoutes(
  app: FastifyInstance,
  options: EntitlementRoutesOptions,
): void {
  const { requireAuth, entitlementService } = options;

  app.get(
    '/v1/entitlements',
    {
      preHandler: [requireAuth],
      schema: {
        tags: ['Account'],
        summary:
          'Fetch authenticated user entitlement, tier limits, and Free vs Plus feature-gate table',
      },
    },
    async (request) => {
      if (!request.authUser) {
        throw unauthorized();
      }
      return entitlementService.getForIdentity(request.authUser);
    },
  );
}
