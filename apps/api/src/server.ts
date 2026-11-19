import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import swagger from '@fastify/swagger';
import swaggerUi from '@fastify/swagger-ui';
import { APP_NAME } from '@peksoft/shared';
import Fastify, { type FastifyInstance } from 'fastify';
import type { AuthProvider } from './auth/firebase-auth.js';
import { FirebaseAuthProvider } from './auth/firebase-auth.js';
import {
  HttpGooglePlayClient,
  type GooglePlayVerifier,
} from './billing/google-play-client.js';
import type { CacheStore } from './cache/cache-store.js';
import { InMemoryLruCache } from './cache/in-memory-lru-cache.js';
import { loadEnv, parseCorsOrigins, type Env } from './config/env.js';
import { createPrismaClient, type DatabaseHandle } from './db/prisma.js';
import { AppError } from './errors/app-error.js';
import { createRequireAuth } from './plugins/auth-middleware.js';
import { registerErrorHandlers } from './plugins/error-handler.js';
import { buildLoggerOptions } from './plugins/logger.js';
import {
  RadioBrowserClient,
  type HttpTransport,
} from './repositories/radio-browser-client.js';
import {
  PrismaEntitlementRepository,
  type EntitlementRepository,
} from './repositories/entitlement-repository.js';
import {
  PrismaLibraryRepository,
  type LibraryRepository,
} from './repositories/library-repository.js';
import {
  PrismaReportRepository,
  type ReportRepository,
} from './repositories/report-repository.js';
import {
  PrismaUserRepository,
  type UserRepository,
} from './repositories/user-repository.js';
import {
  PrismaWebhookEventRepository,
  type WebhookEventRepository,
} from './repositories/webhook-event-repository.js';
import { registerHealthRoutes } from './routes/health.js';
import { registerBillingRoutes } from './routes/v1/billing.js';
import { registerCatalogRoutes } from './routes/v1/catalog.js';
import { registerEntitlementRoutes } from './routes/v1/entitlements.js';
import { registerLibraryRoutes } from './routes/v1/library.js';
import { registerMeRoutes } from './routes/v1/me.js';
import { registerReportRoutes } from './routes/v1/reports.js';
import { registerStationRoutes } from './routes/v1/stations.js';
import { registerWebBillingRoutes } from './routes/v1/web-billing.js';
import { CatalogService } from './services/catalog-service.js';
import { EntitlementService } from './services/entitlement-service.js';
import { GooglePlayBillingService } from './services/google-play-billing-service.js';
import { PaystackProvider } from './services/payment-provider.js';
import { WebBillingService } from './services/web-billing-service.js';
import { LibraryService } from './services/library-service.js';
import { ReportService } from './services/report-service.js';
import { UserService } from './services/user-service.js';

export interface BuildServerOptions {
  env?: Env;
  logger?: boolean;
  enableSwaggerUi?: boolean;
  cache?: CacheStore;
  radioBrowserTransport?: HttpTransport;
  authProvider?: AuthProvider;
  userRepository?: UserRepository;
  entitlementRepository?: EntitlementRepository;
  libraryRepository?: LibraryRepository;
  reportRepository?: ReportRepository;
  webhookEventRepository?: WebhookEventRepository;
  googlePlayVerifier?: GooglePlayVerifier;
  /** Optional hook used by tests to mount ephemeral routes before ready(). */
  registerTestRoutes?: (app: FastifyInstance) => void;
}

export async function buildServer(
  options: BuildServerOptions = {},
): Promise<FastifyInstance> {
  const env = options.env ?? loadEnv();
  const cache = options.cache ?? new InMemoryLruCache({ maxEntries: 500 });
  const radioBrowserClient = new RadioBrowserClient({
    appVersion: env.APP_VERSION,
    cache,
    transport: options.radioBrowserTransport,
  });
  const catalogService = new CatalogService(radioBrowserClient, cache);

  const app = Fastify({
    logger: buildLoggerOptions(env, options.logger ?? true),
    bodyLimit: 256 * 1024, // 256 KiB defense against oversized payload DoS
  });

  registerErrorHandlers(app);

  // Baseline HTTP security headers (OWASP API8:2023)
  app.addHook('onSend', async (_request, reply, payload) => {
    reply.header('X-Content-Type-Options', 'nosniff');
    reply.header('X-Frame-Options', 'DENY');
    reply.header('Referrer-Policy', 'no-referrer');
    reply.header(
      'Permissions-Policy',
      'geolocation=(), microphone=(), camera=()',
    );
    reply.header('X-Permitted-Cross-Domain-Policies', 'none');
    if (env.NODE_ENV === 'production') {
      reply.header(
        'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains',
      );
    }
    return payload;
  });

  await app.register(swagger, {
    openapi: {
      openapi: '3.1.0',
      info: {
        title: `${APP_NAME} API`,
        description:
          'Backend API for station discovery metadata, Firebase authentication, library sync, and entitlements.',
        version: env.APP_VERSION,
      },
      tags: [
        { name: 'System', description: 'Health and service diagnostics' },
        { name: 'Catalog', description: 'Countries, genres, and languages' },
        { name: 'Stations', description: 'Search, trending, and station details' },
        { name: 'Account', description: 'Authenticated user profile and deletion' },
        { name: 'Library', description: 'Favourites, collections, recents, and song history' },
        { name: 'Sync', description: 'Delta synchronisation' },
        { name: 'Reports', description: 'Broken station reporting' },
      ],
    },
  });

  if (options.enableSwaggerUi ?? env.NODE_ENV !== 'production') {
    await app.register(swaggerUi, {
      routePrefix: '/docs',
      uiConfig: {
        docExpansion: 'list',
        deepLinking: false,
      },
    });
  }

  const corsOrigin = parseCorsOrigins(env.CORS_ORIGINS);
  if (env.NODE_ENV === 'production' && corsOrigin === true) {
    throw new Error(
      'CORS_ORIGINS cannot be "*" in production when credentials are enabled.',
    );
  }

  await app.register(cors, {
    origin: corsOrigin,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  await app.register(rateLimit, {
    global: true,
    max: env.RATE_LIMIT_MAX,
    timeWindow: env.RATE_LIMIT_WINDOW_MS,
    errorResponseBuilder: (_request, context) =>
      new AppError({
        statusCode: 429,
        code: 'RATE_LIMIT_EXCEEDED',
        message: `Rate limit exceeded. Retry in ${Math.ceil(context.ttl / 1000)}s.`,
      }),
  });

  registerHealthRoutes(app, env.APP_VERSION);
  registerCatalogRoutes(app, catalogService);
  registerStationRoutes(app, catalogService);

  let dbHandle: DatabaseHandle | undefined;
  let userRepository = options.userRepository;
  let entitlementRepository = options.entitlementRepository;
  let libraryRepository = options.libraryRepository;
  let reportRepository = options.reportRepository;
  let webhookEventRepository = options.webhookEventRepository;
  if (
    (!userRepository ||
      !entitlementRepository ||
      !libraryRepository ||
      !reportRepository ||
      !webhookEventRepository) &&
    env.DATABASE_URL
  ) {
    dbHandle = createPrismaClient(env.DATABASE_URL);
    userRepository ??= new PrismaUserRepository(dbHandle.prisma);
    entitlementRepository ??= new PrismaEntitlementRepository(dbHandle.prisma);
    libraryRepository ??= new PrismaLibraryRepository(dbHandle.prisma);
    reportRepository ??= new PrismaReportRepository(dbHandle.prisma);
    webhookEventRepository ??= new PrismaWebhookEventRepository(dbHandle.prisma);
    app.addHook('onClose', async () => {
      await dbHandle?.close();
    });
  }

  let authProvider = options.authProvider;
  if (!authProvider && env.FIREBASE_PROJECT_ID) {
    authProvider = new FirebaseAuthProvider({
      projectId: env.FIREBASE_PROJECT_ID,
      clientEmail: env.FIREBASE_CLIENT_EMAIL,
      privateKey: env.FIREBASE_PRIVATE_KEY,
    });
  }

  let googlePlayVerifier = options.googlePlayVerifier;
  if (
    !googlePlayVerifier &&
    env.GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL &&
    env.GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY
  ) {
    googlePlayVerifier = new HttpGooglePlayClient({
      serviceAccountEmail: env.GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL,
      privateKey: env.GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY,
    });
  }

  const requireAuth = authProvider ? createRequireAuth(authProvider) : undefined;

  if (authProvider && userRepository && requireAuth) {
    const userService = new UserService(userRepository, authProvider);
    registerMeRoutes(app, { requireAuth, userService });

    if (entitlementRepository) {
      const entitlementService = new EntitlementService(
        userRepository,
        entitlementRepository,
      );
      registerEntitlementRoutes(app, { requireAuth, entitlementService });
    }

    if (libraryRepository) {
      const libraryService = new LibraryService(
        userRepository,
        libraryRepository,
      );
      registerLibraryRoutes(app, { requireAuth, libraryService });
    }
  }

  if (
    googlePlayVerifier &&
    userRepository &&
    entitlementRepository &&
    webhookEventRepository
  ) {
    const entitlementService = new EntitlementService(
      userRepository,
      entitlementRepository,
    );
    const googlePlayBillingService = new GooglePlayBillingService({
      packageName: env.GOOGLE_PLAY_PACKAGE_NAME,
      pubSubVerificationToken: env.GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN,
      verifier: googlePlayVerifier,
      users: userRepository,
      entitlements: entitlementRepository,
      entitlementService,
      webhookEvents: webhookEventRepository,
    });
    registerBillingRoutes(app, {
      googlePlayBillingService,
      requireAuth,
    });
  }

  if (
    env.PAYSTACK_SECRET_KEY &&
    userRepository &&
    entitlementRepository &&
    webhookEventRepository
  ) {
    const entitlementService = new EntitlementService(
      userRepository,
      entitlementRepository,
    );
    const paystackProvider = new PaystackProvider({
      secretKey: env.PAYSTACK_SECRET_KEY,
      planMonthly: env.PAYSTACK_PLAN_MONTHLY,
      planAnnual: env.PAYSTACK_PLAN_ANNUAL,
    });
    const webBillingService = new WebBillingService({
      provider: paystackProvider,
      users: userRepository,
      entitlementService,
      webhookEvents: webhookEventRepository,
    });
    registerWebBillingRoutes(app, {
      webBillingService,
      requireAuth,
    });
  }

  if (reportRepository && userRepository) {
    const reportService = new ReportService(reportRepository, userRepository);
    registerReportRoutes(app, { reportService, authProvider });
  }

  if (options.registerTestRoutes) {
    options.registerTestRoutes(app);
  }

  await app.ready();
  return app;
}
