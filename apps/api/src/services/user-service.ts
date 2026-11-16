import type { AuthProvider, VerifiedIdentity } from '../auth/firebase-auth.js';
import type { UserRepository } from '../repositories/user-repository.js';
import {
  computeEntitlementView,
  type EntitlementView,
  type TierLimits,
} from './entitlement-service.js';

export { computeEntitlementView, type EntitlementView, type TierLimits };

export interface MeResponse {
  user: {
    id: string;
    firebaseUid: string;
    email: string | null;
    displayName: string | null;
    createdAt: string;
  };
  entitlement: EntitlementView;
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
