import type {
  EntitlementSource,
  EntitlementStatus,
  EntitlementTier,
  PrismaClient,
} from '@prisma/client';
import type { VerifiedIdentity } from '../auth/firebase-auth.js';

export interface UserEntitlementRecord {
  tier: EntitlementTier;
  status: EntitlementStatus;
  source: EntitlementSource;
  expiresAt: Date | null;
}

export interface UserWithEntitlementRecord {
  id: string;
  firebaseUid: string;
  email: string | null;
  displayName: string | null;
  createdAt: Date;
  updatedAt: Date;
  entitlement: UserEntitlementRecord;
}

export interface UserRepository {
  findOrCreateByFirebaseUid(
    identity: VerifiedIdentity,
  ): Promise<UserWithEntitlementRecord>;
  deleteByFirebaseUid(firebaseUid: string): Promise<boolean>;
}

export class PrismaUserRepository implements UserRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findOrCreateByFirebaseUid(
    identity: VerifiedIdentity,
  ): Promise<UserWithEntitlementRecord> {
    const user = await this.prisma.user.upsert({
      where: { firebaseUid: identity.uid },
      update: {
        ...(identity.email ? { email: identity.email } : {}),
        ...(identity.displayName ? { displayName: identity.displayName } : {}),
      },
      create: {
        firebaseUid: identity.uid,
        email: identity.email ?? null,
        displayName: identity.displayName ?? null,
        entitlement: {
          create: {
            tier: 'FREE',
            status: 'ACTIVE',
            source: 'NONE',
          },
        },
      },
      include: { entitlement: true },
    });

    const entitlement: UserEntitlementRecord = user.entitlement ?? {
      tier: 'FREE',
      status: 'ACTIVE',
      source: 'NONE',
      expiresAt: null,
    };

    return {
      id: user.id,
      firebaseUid: user.firebaseUid,
      email: user.email,
      displayName: user.displayName,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      entitlement,
    };
  }

  async deleteByFirebaseUid(firebaseUid: string): Promise<boolean> {
    const deleted = await this.prisma.user.deleteMany({
      where: { firebaseUid },
    });
    return deleted.count > 0;
  }
}
