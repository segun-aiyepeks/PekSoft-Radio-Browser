export class AppError extends Error {
  readonly statusCode: number;
  readonly code: string;
  readonly details?: unknown;

  constructor(options: {
    statusCode: number;
    code: string;
    message: string;
    details?: unknown;
  }) {
    super(options.message);
    this.name = 'AppError';
    this.statusCode = options.statusCode;
    this.code = options.code;
    this.details = options.details;
  }
}

export function badRequest(message: string, details?: unknown): AppError {
  return new AppError({
    statusCode: 400,
    code: 'BAD_REQUEST',
    message,
    details,
  });
}

export function unauthorized(message = 'Authentication required'): AppError {
  return new AppError({
    statusCode: 401,
    code: 'UNAUTHORIZED',
    message,
  });
}

export function forbidden(message = 'Access denied'): AppError {
  return new AppError({
    statusCode: 403,
    code: 'FORBIDDEN',
    message,
  });
}

export function notFound(message = 'Resource not found'): AppError {
  return new AppError({
    statusCode: 404,
    code: 'NOT_FOUND',
    message,
  });
}
