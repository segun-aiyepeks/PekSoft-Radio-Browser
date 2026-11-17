import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/auth/presentation/view_models/auth_view_model.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';
import 'package:peksoft_radio/features/subscription/domain/billing_service.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';
import 'package:peksoft_radio/features/subscription/domain/feature_gate.dart';

/// Billing period toggle on [PaywallScreen] (`/paywall`).
enum BillingPeriod { monthly, annual }

/// Immutable state for [PaywallScreen] (`/paywall`) and
/// [SubscriptionManagementScreen] (`/subscription`).
@immutable
class SubscriptionState {
  const SubscriptionState({
    this.entitlement = const Entitlement(),
    this.billingPeriod = BillingPeriod.annual,
    this.products = const <StoreProduct>[],
    this.isProcessing = false,
    this.purchasePending = false,
    this.purchaseSuccess = false,
    this.statusMessage,
    this.error,
  });

  final Entitlement entitlement;
  final BillingPeriod billingPeriod;
  final List<StoreProduct> products;
  final bool isProcessing;
  final bool purchasePending;
  final bool purchaseSuccess;
  final String? statusMessage;
  final AppFailure? error;

  FeatureGate get featureGate => FeatureGate(entitlement);

  bool get hasBillingProblem => entitlement.status == EntitlementStatus.grace;

  bool get isExpired => entitlement.status == EntitlementStatus.expired;

  String get selectedProductId => billingPeriod == BillingPeriod.annual
      ? BillingProductIds.plusAnnual
      : BillingProductIds.plusMonthly;

  StoreProduct? productFor(BillingPeriod period) {
    final String id = period == BillingPeriod.annual
        ? BillingProductIds.plusAnnual
        : BillingProductIds.plusMonthly;
    for (final StoreProduct p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Official Google Play subscription management deep link for this app.
  Uri get manageSubscriptionUri => Uri.parse(
    'https://play.google.com/store/account/subscriptions'
    '?sku=$selectedProductId&package=com.peksoft.radio',
  );

  SubscriptionState copyWith({
    Entitlement? entitlement,
    BillingPeriod? billingPeriod,
    List<StoreProduct>? products,
    bool? isProcessing,
    bool? purchasePending,
    bool? purchaseSuccess,
    String? statusMessage,
    bool clearStatusMessage = false,
    AppFailure? error,
    bool clearError = false,
  }) {
    return SubscriptionState(
      entitlement: entitlement ?? this.entitlement,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      products: products ?? this.products,
      isProcessing: isProcessing ?? this.isProcessing,
      purchasePending: purchasePending ?? this.purchasePending,
      purchaseSuccess: purchaseSuccess ?? this.purchaseSuccess,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for [PaywallScreen] and [SubscriptionManagementScreen].
class SubscriptionViewModel extends AsyncNotifier<SubscriptionState> {
  StreamSubscription<BillingPurchaseUpdate>? _billingSub;

  @override
  Future<SubscriptionState> build() async {
    final BillingService billing = ref.watch(billingServiceProvider);
    await _billingSub?.cancel();
    _billingSub = billing.purchaseUpdates.listen(_onBillingUpdate);
    ref.onDispose(() {
      unawaited(_billingSub?.cancel());
      _billingSub = null;
    });
    return _load();
  }

  void _onBillingUpdate(BillingPurchaseUpdate update) {
    final SubscriptionState current =
        state.asData?.value ?? const SubscriptionState();

    switch (update.state) {
      case BillingPurchaseState.pending:
        state = AsyncValue<SubscriptionState>.data(
          current.copyWith(
            isProcessing: true,
            purchasePending: true,
            purchaseSuccess: false,
            statusMessage:
                'Purchase pending — unlocking as soon as Google Play confirms.',
            clearError: true,
          ),
        );
      case BillingPurchaseState.verified:
        final Entitlement nextEnt = update.entitlement ?? current.entitlement;
        state = AsyncValue<SubscriptionState>.data(
          current.copyWith(
            entitlement: nextEnt,
            isProcessing: false,
            purchasePending: false,
            purchaseSuccess: true,
            statusMessage: 'PekSoft Plus is now active!',
            clearError: true,
          ),
        );
        ref.invalidate(libraryViewModelProvider);
        ref.invalidate(featureGateProvider);
      case BillingPurchaseState.restored:
        unawaited(_finishRestore(current, update.entitlement));
      case BillingPurchaseState.canceled:
        state = AsyncValue<SubscriptionState>.data(
          current.copyWith(
            isProcessing: false,
            purchasePending: false,
            clearError: true,
          ),
        );
      case BillingPurchaseState.error:
        state = AsyncValue<SubscriptionState>.data(
          current.copyWith(
            isProcessing: false,
            purchasePending: false,
            error: update.error,
          ),
        );
    }
  }

  Future<void> _finishRestore(
    SubscriptionState current,
    Entitlement? updated,
  ) async {
    Entitlement resolved = updated ?? current.entitlement;
    if (updated == null) {
      final Result<Entitlement> res = await ref
          .read(entitlementRepositoryProvider)
          .refreshEntitlement();
      if (res case Success<Entitlement>(:final data)) {
        resolved = data;
      }
    }
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(
        entitlement: resolved,
        isProcessing: false,
        purchasePending: false,
        statusMessage: FeatureGate(resolved).isPlus
            ? 'PekSoft Plus restored.'
            : 'No active Plus subscription found.',
      ),
    );
    ref.invalidate(libraryViewModelProvider);
    ref.invalidate(featureGateProvider);
  }

  void selectBillingPeriod(BillingPeriod period) {
    final SubscriptionState? current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(
        billingPeriod: period,
        clearStatusMessage: true,
        clearError: true,
      ),
    );
  }

  void clearPurchaseSuccess() {
    final SubscriptionState? current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(purchaseSuccess: false, clearStatusMessage: true),
    );
  }

  Future<void> startPurchase() async {
    final SubscriptionState current =
        state.asData?.value ?? const SubscriptionState();
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(
        isProcessing: true,
        purchasePending: false,
        clearError: true,
        clearStatusMessage: true,
      ),
    );

    final String? uid = ref.read(authViewModelProvider).uid;
    try {
      await ref
          .read(billingServiceProvider)
          .purchaseSubscription(
            current.selectedProductId,
            obfuscatedAccountId: uid,
          );
    } catch (error) {
      state = AsyncValue<SubscriptionState>.data(
        current.copyWith(
          isProcessing: false,
          error: AppFailure.network(
            message: 'Unable to start purchase: $error',
          ),
        ),
      );
    }
  }

  Future<void> restorePurchases() async {
    final SubscriptionState current =
        state.asData?.value ?? const SubscriptionState();
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(isProcessing: true, clearError: true),
    );
    try {
      await ref.read(billingServiceProvider).restorePurchases();
    } catch (_) {
      // Fall back to direct server entitlement refresh if store restore fails.
    }
    final Result<Entitlement> res = await ref
        .read(entitlementRepositoryProvider)
        .refreshEntitlement();
    state = AsyncValue<SubscriptionState>.data(switch (res) {
      Success<Entitlement>(:final data) => current.copyWith(
        entitlement: data,
        isProcessing: false,
        statusMessage: FeatureGate(data).isPlus
            ? 'PekSoft Plus restored.'
            : 'No active Plus subscription found.',
      ),
      Failure<Entitlement>(:final error) => current.copyWith(
        isProcessing: false,
        error: error,
      ),
    });
    ref.invalidate(libraryViewModelProvider);
    ref.invalidate(featureGateProvider);
  }

  Future<void> watchRewardedAdForPlusPass() async {
    final SubscriptionState current =
        state.asData?.value ?? const SubscriptionState();
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(isProcessing: true, clearError: true),
    );
    final Result<Entitlement> res = await ref
        .read(adServiceProvider)
        .showRewardedAdForPlusPass(
          entitlementRepository: ref.read(entitlementRepositoryProvider),
        );
    state = AsyncValue<SubscriptionState>.data(switch (res) {
      Success<Entitlement>(:final data) => current.copyWith(
        entitlement: data,
        isProcessing: false,
        statusMessage: '24 hours of Plus convenience features unlocked!',
      ),
      Failure<Entitlement>(:final error) => current.copyWith(
        isProcessing: false,
        error: error,
      ),
    });
    ref.invalidate(libraryViewModelProvider);
    ref.invalidate(featureGateProvider);
  }

  Future<void> refresh() async {
    state = const AsyncValue<SubscriptionState>.loading();
    state = AsyncValue<SubscriptionState>.data(await _load());
  }

  Future<SubscriptionState> _load() async {
    final Future<Result<Entitlement>> entFuture = ref
        .read(entitlementRepositoryProvider)
        .getEntitlement();
    final Future<List<StoreProduct>> productsFuture = ref
        .read(billingServiceProvider)
        .loadProducts()
        .catchError((_) => const <StoreProduct>[]);

    final Result<Entitlement> res = await entFuture;
    final List<StoreProduct> products = await productsFuture;

    return switch (res) {
      Success<Entitlement>(:final data) => SubscriptionState(
        entitlement: data,
        products: products,
      ),
      Failure<Entitlement>(:final error) => SubscriptionState(
        products: products,
        error: error,
      ),
    };
  }
}

final AsyncNotifierProvider<SubscriptionViewModel, SubscriptionState>
subscriptionViewModelProvider =
    AsyncNotifierProvider<SubscriptionViewModel, SubscriptionState>(
      SubscriptionViewModel.new,
    );
