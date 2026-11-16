import type { StationReportInput } from '@peksoft/shared';
import type { PrismaClient, ReportReason, ReportStatus } from '@prisma/client';

export interface StationReportRecord {
  id: string;
  userId: string | null;
  stationId: string;
  stationName: string;
  reason: ReportReason;
  notes: string | null;
  status: ReportStatus;
  createdAt: Date;
}

export interface ReportRepository {
  createReport(options: {
    userId: string | null;
    input: StationReportInput;
  }): Promise<StationReportRecord>;
}

export class PrismaReportRepository implements ReportRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async createReport(options: {
    userId: string | null;
    input: StationReportInput;
  }): Promise<StationReportRecord> {
    return this.prisma.stationReport.create({
      data: {
        userId: options.userId,
        stationId: options.input.stationId,
        stationName: options.input.stationName,
        reason: options.input.reason,
        notes: options.input.notes ?? null,
      },
    });
  }
}
