import type { FastifyInstance, preHandlerHookHandler } from 'fastify';
import { unauthorized } from '../../errors/app-error.js';
import type { UserService } from '../../services/user-service.js';

export function registerMeRoutes(
  app: FastifyInstance,
  options: {
    requireAuth: preHandlerHookHandler;
    userService: UserService;
  },
): void {
  app.get(
    '/v1/me',
    {
      preHandler: options.requireAuth,
      schema: {
        tags: ['Account'],
        summary: 'Get or create the authenticated user profile and entitlement',
      },
    },
    async (request) => {
      if (!request.authUser) {
        throw unauthorized();
      }
      return options.userService.getOrCreateMe(request.authUser);
    },
  );

  app.delete(
    '/v1/me',
    {
      preHandler: options.requireAuth,
      schema: {
        tags: ['Account'],
        summary: 'Delete user data in PostgreSQL and the Firebase Auth account',
      },
    },
    async (request, reply) => {
      if (!request.authUser) {
        throw unauthorized();
      }
      await options.userService.deleteMe(request.authUser);
      return reply.status(204).send();
    },
  );
}
