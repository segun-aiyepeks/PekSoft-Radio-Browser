import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/subscription/domain/entitlement.dart';

/// Billing period toggle on [PaywallScreen] (`/paywall`).
enum BillingPeriod { monthly, annual }

/// Immutable state for [PaywallScreen] (`/paywall`) and
/// [SubscriptionManagementScreen] (`/subscription`).
@immutable
class SubscriptionState {
  const SubscriptionState({
    this.entitlement = const Entitlement(),
    this.billingPeriod = BillingPeriod.annual,
    this.isProcessing = false,
    this.statusMessage,
    this.error,
  });

  final Entitlement entitlement;
  final BillingPeriod billingPeriod;
  final bool isProcessing;
  final String? statusMessage;
  final AppFailure? error;

  SubscriptionState copyWith({
    Entitlement? entitlement,
    BillingPeriod? billingPeriod,
    bool? isProcessing,
    String? statusMessage,
    bool clearStatusMessage = false,
    AppFailure? error,
    bool clearError = false,
  }) {
    return SubscriptionState(
      entitlement: entitlement ?? this.entitlement,
      billingPeriod: billingPeriod ?? this.billingPeriod,
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: clearStatusMessage
          ? null
          : (statusMessage ?? this.statusMessage),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for [PaywallScreen] and [SubscriptionManagementScreen].
class SubscriptionViewModel extends AsyncNotifier<SubscriptionState> {
  @override
  Future<SubscriptionState> build() => _load();

  void selectBillingPeriod(BillingPeriod period) {
    final SubscriptionState? current = state.asData?.value;
    if (current == null) return;
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(billingPeriod: period, clearStatusMessage: true),
    );
  }

  Future<void> restorePurchases() async {
    final SubscriptionState current =
        state.asData?.value ?? const SubscriptionState();
    state = AsyncValue<SubscriptionState>.data(
      current.copyWith(isProcessing: true, clearError: true),
    );
    final Result<Entitlement> res = await ref
        .read(entitlementRepositoryProvider)
        .refreshEntitlement();
    state = AsyncValue<SubscriptionState>.data(switch (res) {
      Success<Entitlement>(:final data) => current.copyWith(
        entitlement: data,
        isProcessing: false,
        statusMessage: data.tier == EntitlementTier.pro
            ? 'PekSoft Pro restored.'
            : 'No active Pro subscription found.',
      ),
      Failure<Entitlement>(:final error) => current.copyWith(
        isProcessing: false,
        error: error,
      ),
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue<SubscriptionState>.loading();
    state = AsyncValue<SubscriptionState>.data(await _load());
  }

  Future<SubscriptionState> _load() async {
    final Result<Entitlement> res = await ref
        .read(entitlementRepositoryProvider)
        .getEntitlement();
    return switch (res) {
      Success<Entitlement>(:final data) => SubscriptionState(entitlement: data),
      Failure<Entitlement>(:final error) => SubscriptionState(error: error),
    };
  }
}

final AsyncNotifierProvider<SubscriptionViewModel, SubscriptionState>
subscriptionViewModelProvider =
    AsyncNotifierProvider<SubscriptionViewModel, SubscriptionState>(
      SubscriptionViewModel.new,
    );
