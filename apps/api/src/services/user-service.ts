import type { AuthProvider, VerifiedIdentity } from '../auth/firebase-auth.js';
import type {
  UserEntitlementRecord,
  UserRepository,
} from '../repositories/user-repository.js';

export interface TierLimits {
  maxFavorites: number | null;
  maxCollections: number | null;
  maxSongHistory: number | null;
}

export interface MeResponse {
  user: {
    id: string;
    firebaseUid: string;
    email: string | null;
    displayName: string | null;
    createdAt: string;
  };
  entitlement: {
    tier: 'FREE' | 'PLUS';
    status: string;
    adsEnabled: boolean;
    expiresAt: string | null;
    limits: TierLimits;
  };
}

export function computeEntitlementView(entitlement: UserEntitlementRecord) {
  const isPlus =
    entitlement.tier === 'PLUS' &&
    (entitlement.status === 'ACTIVE' || entitlement.status === 'GRACE') &&
    (!entitlement.expiresAt || entitlement.expiresAt.getTime() > Date.now());

  return {
    tier: isPlus ? ('PLUS' as const) : ('FREE' as const),
    status: entitlement.status,
    adsEnabled: !isPlus,
    expiresAt: entitlement.expiresAt
      ? entitlement.expiresAt.toISOString()
      : null,
    limits: isPlus
      ? { maxFavorites: null, maxCollections: null, maxSongHistory: null }
      : { maxFavorites: 10, maxCollections: 2, maxSongHistory: 10 },
  };
}

export class UserService {
  constructor(
    private readonly users: UserRepository,
    private readonly authProvider: AuthProvider,
  ) {}

  async getOrCreateMe(identity: VerifiedIdentity): Promise<MeResponse> {
    const record = await this.users.findOrCreateByFirebaseUid(identity);
    return {
      user: {
        id: record.id,
        firebaseUid: record.firebaseUid,
        email: record.email,
        displayName: record.displayName,
        createdAt: record.createdAt.toISOString(),
      },
      entitlement: computeEntitlementView(record.entitlement),
    };
  }

  async deleteMe(identity: VerifiedIdentity): Promise<void> {
    await this.users.deleteByFirebaseUid(identity.uid);
    await this.authProvider.deleteUser(identity.uid);
  }
}
