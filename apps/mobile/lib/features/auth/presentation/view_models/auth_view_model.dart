import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/di/providers.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/core/network/api_client.dart';
import 'package:peksoft_radio/features/auth/domain/auth_repository.dart';
import 'package:peksoft_radio/features/library/domain/sync_repository.dart';
import 'package:peksoft_radio/features/library/presentation/view_models/library_view_model.dart';

/// Immutable state for Auth and Profile screens.
@immutable
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.userUid,
    this.userEmail,
    this.displayName,
    this.emailVerified = false,
    this.isLoading = false,
    this.verificationEmailSent = false,
    this.resetEmailSent = false,
    this.pendingLinkEmail,
    this.pendingLinkCredential,
    this.lastSyncSummary,
    this.error,
  });

  final bool isAuthenticated;
  final String? userUid;
  final String? userEmail;
  final String? displayName;
  final bool emailVerified;
  final bool isLoading;
  final bool verificationEmailSent;
  final bool resetEmailSent;
  final String? pendingLinkEmail;
  final Object? pendingLinkCredential;
  final SyncSummary? lastSyncSummary;
  final AppFailure? error;

  AuthState copyWith({
    bool? isAuthenticated,
    String? userUid,
    String? userEmail,
    String? displayName,
    bool? emailVerified,
    bool? isLoading,
    bool? verificationEmailSent,
    bool? resetEmailSent,
    String? pendingLinkEmail,
    Object? pendingLinkCredential,
    bool clearPendingLink = false,
    SyncSummary? lastSyncSummary,
    AppFailure? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userUid: userUid ?? this.userUid,
      userEmail: userEmail ?? this.userEmail,
      displayName: displayName ?? this.displayName,
      emailVerified: emailVerified ?? this.emailVerified,
      isLoading: isLoading ?? this.isLoading,
      verificationEmailSent:
          verificationEmailSent ?? this.verificationEmailSent,
      resetEmailSent: resetEmailSent ?? this.resetEmailSent,
      pendingLinkEmail: clearPendingLink
          ? null
          : (pendingLinkEmail ?? this.pendingLinkEmail),
      pendingLinkCredential: clearPendingLink
          ? null
          : (pendingLinkCredential ?? this.pendingLinkCredential),
      lastSyncSummary: lastSyncSummary ?? this.lastSyncSummary,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthViewModel extends Notifier<AuthState> {
  StreamSubscription<AuthUser?>? _authSub;

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  ApiClient get _api => ref.read(apiClientProvider);
  SyncRepository get _sync => ref.read(syncRepositoryProvider);

  @override
  AuthState build() {
    _authSub?.cancel();
    _authSub = _auth.authStateChanges.listen((AuthUser? user) {
      if (user == null) {
        state = const AuthState();
      } else {
        state = state.copyWith(
          isAuthenticated: true,
          userUid: user.uid,
          userEmail: user.email,
          displayName: user.displayName ?? user.email?.split('@').first,
          emailVerified: user.emailVerified,
          clearError: true,
        );
      }
    });
    ref.onDispose(() {
      _authSub?.cancel();
      _authSub = null;
    });

    final AuthUser? current = _auth.currentUser;
    if (current != null) {
      return AuthState(
        isAuthenticated: true,
        userUid: current.uid,
        userEmail: current.email,
        displayName: current.displayName ?? current.email?.split('@').first,
        emailVerified: current.emailVerified,
      );
    }
    return const AuthState();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    final String cleanEmail = email.trim();
    if (!_isValidEmail(cleanEmail) || password.length < 6) {
      state = state.copyWith(
        error: const AppFailure.validation(
          message: 'Enter a valid email and a password of at least 6 chars.',
        ),
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (state.pendingLinkCredential != null &&
        state.pendingLinkEmail?.toLowerCase() == cleanEmail.toLowerCase()) {
      return completeAccountLinkWithPassword(password);
    }

    final Result<AuthOutcome> res = await _auth.signInWithEmail(
      email: cleanEmail,
      password: password,
    );
    return _handleAuthOutcome(res);
  }

  Future<bool> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final String cleanEmail = email.trim();
    final String cleanName = displayName.trim();
    if (!_isValidEmail(cleanEmail) ||
        password.length < 6 ||
        cleanName.isEmpty) {
      state = state.copyWith(
        error: const AppFailure.validation(
          message: 'Please provide name, valid email, and 6+ char password.',
        ),
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    final Result<AuthUser> res = await _auth.signUpWithEmail(
      email: cleanEmail,
      password: password,
      displayName: cleanName,
    );
    switch (res) {
      case Success<AuthUser>(data: final AuthUser user):
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userUid: user.uid,
          userEmail: user.email,
          displayName: user.displayName ?? cleanName,
          emailVerified: user.emailVerified,
          verificationEmailSent: true,
          clearPendingLink: true,
          clearError: true,
        );
        await _syncAfterSignIn();
        return true;
      case Failure<AuthUser>(error: final AppFailure error):
        state = state.copyWith(isLoading: false, error: error);
        return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final Result<AuthOutcome> res = await _auth.signInWithGoogle();
    return _handleAuthOutcome(res);
  }

  Future<bool> completeAccountLinkWithPassword(String password) async {
    final String? email = state.pendingLinkEmail;
    final Object? pending = state.pendingLinkCredential;
    if (email == null || pending == null) {
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    final Result<AuthUser> res = await _auth.linkPendingCredentialWithPassword(
      email: email,
      password: password,
      pendingCredential: pending,
    );
    switch (res) {
      case Success<AuthUser>(data: final AuthUser user):
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userUid: user.uid,
          userEmail: user.email,
          displayName: user.displayName ?? user.email?.split('@').first,
          emailVerified: user.emailVerified,
          clearPendingLink: true,
          clearError: true,
        );
        await _syncAfterSignIn();
        return true;
      case Failure<AuthUser>(error: final AppFailure error):
        state = state.copyWith(isLoading: false, error: error);
        return false;
    }
  }

  Future<bool> _handleAuthOutcome(Result<AuthOutcome> res) async {
    switch (res) {
      case Success<AuthOutcome>(data: final AuthSuccess success):
        final AuthUser user = success.user;
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          userUid: user.uid,
          userEmail: user.email,
          displayName: user.displayName ?? user.email?.split('@').first,
          emailVerified: user.emailVerified,
          clearPendingLink: true,
          clearError: true,
        );
        await _syncAfterSignIn();
        return true;
      case Success<AuthOutcome>(data: final AuthAccountLinkRequired link):
        state = state.copyWith(
          isLoading: false,
          pendingLinkEmail: link.email,
          pendingLinkCredential: link.pendingCredential,
          error: AppFailure.validation(
            message:
                'An account already exists for ${link.email}. Sign in with your password to link Google.',
          ),
        );
        return false;
      case Failure<AuthOutcome>(error: final AppFailure error):
        state = state.copyWith(isLoading: false, error: error);
        return false;
    }
  }

  Future<void> _syncAfterSignIn() async {
    final Result<SyncSummary> syncRes = await _sync.syncOnSignIn();
    if (syncRes case Success<SyncSummary>(data: final SyncSummary summary)) {
      state = state.copyWith(lastSyncSummary: summary);
      ref.invalidate(libraryViewModelProvider);
    }
  }

  Future<bool> syncNow() async {
    if (!state.isAuthenticated) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    final Result<SyncSummary> res = await _sync.syncNow();
    switch (res) {
      case Success<SyncSummary>(data: final SyncSummary summary):
        state = state.copyWith(isLoading: false, lastSyncSummary: summary);
        ref.invalidate(libraryViewModelProvider);
        return true;
      case Failure<SyncSummary>(error: final AppFailure error):
        state = state.copyWith(isLoading: false, error: error);
        return false;
    }
  }

  Future<bool> resendVerificationEmail() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final Result<void> res = await _auth.sendEmailVerification();
    switch (res) {
      case Success<void>():
        state = state.copyWith(isLoading: false, verificationEmailSent: true);
        return true;
      case Failure<void>(error: final AppFailure error):
        state = state.copyWith(isLoading: false, error: error);
        return false;
    }
  }

  Future<bool> reloadVerificationStatus() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final Result<AuthUser?> res = await _auth.reloadUser();
    switch (res) {
      case Success<AuthUser?>(data: final AuthUser? user):
        if (user == null) {
          state = state.copyWith(isLoading: false);
          return false;
        }
        state = state.copyWith(
          isLoading: false,
          emailVerified: user.emailVerified,
        );
        return user.emailVerified;
      case Failure<AuthUser?>(error: final AppFailure error):
        state = state.copyWith(isLoading: false, error: error);
        return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final String cleanEmail = email.trim();
    if (!_isValidEmail(cleanEmail)) {
      state = state.copyWith(
        error: const AppFailure.validation(
          message: 'Enter a valid email address.',
        ),
      );
      return false;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    final Result<void> res = await _auth.sendPasswordResetEmail(cleanEmail);
    switch (res) {
      case Success<void>():
        state = state.copyWith(isLoading: false, resetEmailSent: true);
        return true;
      case Failure<void>(error: final AppFailure error):
        state = state.copyWith(isLoading: false, error: error);
        return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _auth.signOut();
    state = const AuthState();
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final Result<void> apiRes = await _api.deleteMe();
    if (apiRes case Failure<void>(error: final AppFailure error)) {
      final Result<void> fbRes = await _auth.deleteFirebaseUser();
      if (fbRes is Failure<void>) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      }
    }
    await _auth.signOut();
    state = const AuthState();
    return true;
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }
}

final NotifierProvider<AuthViewModel, AuthState> authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
