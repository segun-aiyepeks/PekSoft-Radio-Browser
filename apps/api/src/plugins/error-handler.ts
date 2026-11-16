import type { FastifyError, FastifyInstance } from 'fastify';
import { ZodError } from 'zod';
import { AppError } from '../errors/app-error.js';

export interface ErrorEnvelope {
  error: {
    code: string;
    message: string;
    requestId: string;
    details?: unknown;
  };
}

export function registerErrorHandlers(app: FastifyInstance): void {
  app.setNotFoundHandler((request, reply) => {
    const body: ErrorEnvelope = {
      error: {
        code: 'NOT_FOUND',
        message: `Route ${request.method} ${request.url} not found`,
        requestId: request.id,
      },
    };
    return reply.status(404).send(body);
  });

  app.setErrorHandler((error, request, reply) => {
    if (error instanceof AppError) {
      const body: ErrorEnvelope = {
        error: {
          code: error.code,
          message: error.message,
          requestId: request.id,
          ...(error.details !== undefined ? { details: error.details } : {}),
        },
      };
      return reply.status(error.statusCode).send(body);
    }

    if (error instanceof ZodError) {
      const body: ErrorEnvelope = {
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Request validation failed',
          requestId: request.id,
          details: error.issues.map((issue) => ({
            path: issue.path.join('.'),
            message: issue.message,
          })),
        },
      };
      return reply.status(400).send(body);
    }

    const fastifyErr = error as FastifyError;
    if (fastifyErr.validation) {
      const body: ErrorEnvelope = {
        error: {
          code: 'VALIDATION_ERROR',
          message: fastifyErr.message,
          requestId: request.id,
          details: fastifyErr.validation,
        },
      };
      return reply.status(400).send(body);
    }

    const statusCode = fastifyErr.statusCode ?? 500;
    if (statusCode < 500) {
      const body: ErrorEnvelope = {
        error: {
          code: fastifyErr.code || 'REQUEST_ERROR',
          message: fastifyErr.message,
          requestId: request.id,
        },
      };
      return reply.status(statusCode).send(body);
    }

    request.log.error(
      { err: error, requestId: request.id },
      'Unhandled server error',
    );

    const body: ErrorEnvelope = {
      error: {
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
        requestId: request.id,
      },
    };
    return reply.status(500).send(body);
  });
}
