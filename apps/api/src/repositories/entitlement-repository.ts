import type {
  EntitlementSource,
  EntitlementStatus,
  EntitlementTier,
  PrismaClient,
} from '@prisma/client';

export interface EntitlementRecord {
  id: string;
  userId: string;
  tier: EntitlementTier;
  status: EntitlementStatus;
  source: EntitlementSource;
  externalCustomerId: string | null;
  externalSubscriptionId: string | null;
  expiresAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface UpsertEntitlementInput {
  tier: EntitlementTier;
  status: EntitlementStatus;
  source: EntitlementSource;
  externalCustomerId?: string | null;
  externalSubscriptionId?: string | null;
  expiresAt?: Date | null;
}

export interface EntitlementRepository {
  findByUserId(userId: string): Promise<EntitlementRecord | null>;
  findByExternalSubscriptionId(
    source: EntitlementSource,
    externalSubscriptionId: string,
  ): Promise<EntitlementRecord | null>;
  upsertByUserId(
    userId: string,
    input: UpsertEntitlementInput,
  ): Promise<EntitlementRecord>;
}

export class PrismaEntitlementRepository implements EntitlementRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findByUserId(userId: string): Promise<EntitlementRecord | null> {
    return this.prisma.entitlement.findUnique({
      where: { userId },
    });
  }

  async findByExternalSubscriptionId(
    source: EntitlementSource,
    externalSubscriptionId: string,
  ): Promise<EntitlementRecord | null> {
    return this.prisma.entitlement.findFirst({
      where: {
        source,
        externalSubscriptionId,
      },
    });
  }

  async upsertByUserId(
    userId: string,
    input: UpsertEntitlementInput,
  ): Promise<EntitlementRecord> {
    return this.prisma.entitlement.upsert({
      where: { userId },
      update: {
        tier: input.tier,
        status: input.status,
        source: input.source,
        externalCustomerId: input.externalCustomerId ?? null,
        externalSubscriptionId: input.externalSubscriptionId ?? null,
        expiresAt: input.expiresAt ?? null,
      },
      create: {
        userId,
        tier: input.tier,
        status: input.status,
        source: input.source,
        externalCustomerId: input.externalCustomerId ?? null,
        externalSubscriptionId: input.externalSubscriptionId ?? null,
        expiresAt: input.expiresAt ?? null,
      },
    });
  }
}
