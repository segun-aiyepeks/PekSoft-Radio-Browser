import { stationReportInputSchema } from '@peksoft/shared';
import type { FastifyInstance } from 'fastify';
import type { AuthProvider, VerifiedIdentity } from '../../auth/firebase-auth.js';
import type { ReportService } from '../../services/report-service.js';

export function registerReportRoutes(
  app: FastifyInstance,
  options: {
    reportService: ReportService;
    authProvider?: AuthProvider;
  },
): void {
  app.post(
    '/v1/reports',
    {
      config: {
        rateLimit: {
          max: 15,
          timeWindow: 60_000,
        },
      },
      schema: {
        tags: ['Reports'],
        summary: 'Submit a broken station or metadata report',
      },
    },
    async (request, reply) => {
      const input = stationReportInputSchema.parse(request.body);
      let identity: VerifiedIdentity | undefined;

      const header = request.headers.authorization;
      if (options.authProvider && header?.startsWith('Bearer ')) {
        const token = header.slice('Bearer '.length).trim();
        if (token) {
          identity = await options.authProvider.verifyIdToken(token);
        }
      }

      const report = await options.reportService.submitReport({
        identity,
        input,
      });
      return reply.status(201).send({ report });
    },
  );
}
