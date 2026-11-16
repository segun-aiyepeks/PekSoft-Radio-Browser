import type { preHandlerHookHandler } from 'fastify';
import type { AuthProvider, VerifiedIdentity } from '../auth/firebase-auth.js';
import { unauthorized } from '../errors/app-error.js';

declare module 'fastify' {
  interface FastifyRequest {
    authUser?: VerifiedIdentity;
  }
}

export function createRequireAuth(
  authProvider: AuthProvider,
): preHandlerHookHandler {
  return async (request) => {
    const header = request.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      throw unauthorized('Missing or invalid Authorization Bearer header');
    }

    const token = header.slice('Bearer '.length).trim();
    if (!token) {
      throw unauthorized('Empty authentication token');
    }

    request.authUser = await authProvider.verifyIdToken(token);
  };
}
