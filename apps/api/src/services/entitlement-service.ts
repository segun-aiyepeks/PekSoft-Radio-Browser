import {
  PLAN_FEATURE_GATES,
  fromPrismaEntitlementSource,
  getPlanFeatureGate,
  toPrismaEntitlementSource,
  type EntitlementTier,
  type PaymentProviderSource,
  type PlanFeatureGate,
} from '@peksoft/shared';
import type { VerifiedIdentity } from '../auth/firebase-auth.js';
import type {
  EntitlementRecord,
  EntitlementRepository,
} from '../repositories/entitlement-repository.js';
import type {
  UserEntitlementRecord,
  UserRepository,
} from '../repositories/user-repository.js';

export interface TierLimits {
  maxFavorites: number | null;
  maxCollections: number | null;
  maxRecentlyPlayed: number;
  maxSongHistory: number | null;
}

export interface EntitlementView {
  tier: EntitlementTier;
  status: 'ACTIVE' | 'GRACE' | 'EXPIRED' | 'CANCELLED';
  source: 'none' | 'promo' | PaymentProviderSource;
  adsEnabled: boolean;
  expiresAt: string | null;
  externalCustomerId: string | null;
  externalSubscriptionId: string | null;
  limits: TierLimits;
  features: PlanFeatureGate;
}

export interface EntitlementsEndpointResponse {
  entitlement: EntitlementView;
  plans: Record<EntitlementTier, PlanFeatureGate>;
}

export interface GrantEntitlementParams {
  userId: string;
  source: PaymentProviderSource;
  status?: 'ACTIVE' | 'GRACE';
  externalCustomerId?: string | null;
  externalSubscriptionId?: string | null;
  expiresAt?: Date | null;
}

export interface RevokeEntitlementParams {
  userId: string;
  source: PaymentProviderSource;
  status?: 'EXPIRED' | 'CANCELLED';
  externalSubscriptionId?: string | null;
  expiresAt?: Date | null;
}

export interface EntitlementMutationResult {
  entitlement: EntitlementView;
  applied: boolean;
}

export function computeEntitlementView(
  entitlement: UserEntitlementRecord | EntitlementRecord,
  now: Date = new Date(),
): EntitlementView {
  const isExpiredByClock =
    entitlement.expiresAt !== null &&
    entitlement.expiresAt.getTime() <= now.getTime();

  const isPlus =
    entitlement.tier === 'PLUS' &&
    (entitlement.status === 'ACTIVE' || entitlement.status === 'GRACE') &&
    !isExpiredByClock;

  const effectiveTier: EntitlementTier = isPlus ? 'PLUS' : 'FREE';
  const effectiveStatus =
    entitlement.tier === 'PLUS' && isExpiredByClock
      ? ('EXPIRED' as const)
      : entitlement.status;

  const gate = getPlanFeatureGate(effectiveTier);

  return {
    tier: effectiveTier,
    status: effectiveStatus,
    source: fromPrismaEntitlementSource(entitlement.source),
    adsEnabled: gate.adsEnabled,
    expiresAt: entitlement.expiresAt
      ? entitlement.expiresAt.toISOString()
      : null,
    externalCustomerId:
      'externalCustomerId' in entitlement
        ? entitlement.externalCustomerId
        : null,
    externalSubscriptionId:
      'externalSubscriptionId' in entitlement
        ? entitlement.externalSubscriptionId
        : null,
    limits: {
      maxFavorites: gate.maxFavorites,
      maxCollections: gate.maxCollections,
      maxRecentlyPlayed: gate.maxRecentlyPlayed,
      maxSongHistory: gate.maxSongHistory,
    },
    features: gate,
  };
}

function sameTime(a: Date | null | undefined, b: Date | null | undefined): boolean {
  if (!a && !b) return true;
  if (!a || !b) return false;
  return a.getTime() === b.getTime();
}

export class EntitlementService {
  constructor(
    private readonly users: UserRepository,
    private readonly entitlements: EntitlementRepository,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async getForIdentity(
    identity: VerifiedIdentity,
  ): Promise<EntitlementsEndpointResponse> {
    const user = await this.users.findOrCreateByFirebaseUid(identity);
    const stored =
      (await this.entitlements.findByUserId(user.id)) ?? user.entitlement;

    return {
      entitlement: computeEntitlementView(stored, this.now()),
      plans: PLAN_FEATURE_GATES,
    };
  }

  /**
   * Idempotent Plus grant operation recording the payment provider source
   * ('google_play' or 'paystack').
   */
  async grantPlus(
    params: GrantEntitlementParams,
  ): Promise<EntitlementMutationResult> {
    const prismaSource = toPrismaEntitlementSource(params.source);
    const targetStatus = params.status ?? 'ACTIVE';
    const targetCustomerId = params.externalCustomerId ?? null;
    const targetSubId = params.externalSubscriptionId ?? null;
    const targetExpiresAt = params.expiresAt ?? null;

    const existing = await this.entitlements.findByUserId(params.userId);
    if (existing) {
      const sameSourceAndStatus =
        existing.tier === 'PLUS' &&
        existing.source === prismaSource &&
        existing.status === targetStatus &&
        existing.externalCustomerId === targetCustomerId &&
        existing.externalSubscriptionId === targetSubId;

      const expiryCovered =
        sameTime(existing.expiresAt, targetExpiresAt) ||
        (existing.expiresAt !== null &&
          targetExpiresAt !== null &&
          existing.expiresAt.getTime() >= targetExpiresAt.getTime());

      if (sameSourceAndStatus && expiryCovered) {
        return {
          entitlement: computeEntitlementView(existing, this.now()),
          applied: false,
        };
      }
    }

    const saved = await this.entitlements.upsertByUserId(params.userId, {
      tier: 'PLUS',
      status: targetStatus,
      source: prismaSource,
      externalCustomerId: targetCustomerId ?? existing?.externalCustomerId ?? null,
      externalSubscriptionId:
        targetSubId ?? existing?.externalSubscriptionId ?? null,
      expiresAt: targetExpiresAt,
    });

    return {
      entitlement: computeEntitlementView(saved, this.now()),
      applied: true,
    };
  }

  /**
   * Idempotent Plus revoke operation recording the payment provider source
   * ('google_play' or 'paystack').
   */
  async revokePlus(
    params: RevokeEntitlementParams,
  ): Promise<EntitlementMutationResult> {
    const prismaSource = toPrismaEntitlementSource(params.source);
    const targetStatus = params.status ?? 'EXPIRED';
    const existing = await this.entitlements.findByUserId(params.userId);

    if (existing) {
      // Do not clobber an active subscription owned by a different payment provider
      if (
        existing.tier === 'PLUS' &&
        existing.source !== 'NONE' &&
        existing.source !== prismaSource
      ) {
        return {
          entitlement: computeEntitlementView(existing, this.now()),
          applied: false,
        };
      }

      const targetExpires = params.expiresAt ?? existing.expiresAt ?? null;
      if (
        existing.tier === 'FREE' &&
        existing.source === prismaSource &&
        existing.status === targetStatus &&
        sameTime(existing.expiresAt, targetExpires)
      ) {
        return {
          entitlement: computeEntitlementView(existing, this.now()),
          applied: false,
        };
      }

      const saved = await this.entitlements.upsertByUserId(params.userId, {
        tier: 'FREE',
        status: targetStatus,
        source: prismaSource,
        externalCustomerId: existing.externalCustomerId,
        externalSubscriptionId:
          params.externalSubscriptionId ?? existing.externalSubscriptionId,
        expiresAt: targetExpires,
      });

      return {
        entitlement: computeEntitlementView(saved, this.now()),
        applied: true,
      };
    }

    const saved = await this.entitlements.upsertByUserId(params.userId, {
      tier: 'FREE',
      status: targetStatus,
      source: prismaSource,
      externalCustomerId: null,
      externalSubscriptionId: params.externalSubscriptionId ?? null,
      expiresAt: params.expiresAt ?? null,
    });

    return {
      entitlement: computeEntitlementView(saved, this.now()),
      applied: true,
    };
  }
}
