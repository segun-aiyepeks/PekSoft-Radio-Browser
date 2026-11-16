import type { StationReportInput } from '@peksoft/shared';
import type { VerifiedIdentity } from '../auth/firebase-auth.js';
import type {
  ReportRepository,
  StationReportRecord,
} from '../repositories/report-repository.js';
import type { UserRepository } from '../repositories/user-repository.js';

export class ReportService {
  constructor(
    private readonly reports: ReportRepository,
    private readonly users: UserRepository,
  ) {}

  async submitReport(options: {
    identity?: VerifiedIdentity;
    input: StationReportInput;
  }): Promise<StationReportRecord> {
    let userId: string | null = null;
    if (options.identity) {
      const user = await this.users.findOrCreateByFirebaseUid(options.identity);
      userId = user.id;
    }
    return this.reports.createReport({
      userId,
      input: options.input,
    });
  }
}
