import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';

/// Immutable state for all Auth screens (`/auth`, `/auth/sign-in`,
/// `/auth/sign-up`, `/auth/verify-email`, `/auth/forgot-password`,
/// `/auth/reset-password`).
@immutable
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.userEmail,
    this.displayName,
    this.isLoading = false,
    this.verificationEmailSent = false,
    this.resetEmailSent = false,
    this.passwordResetCompleted = false,
    this.error,
  });

  final bool isAuthenticated;
  final String? userEmail;
  final String? displayName;
  final bool isLoading;
  final bool verificationEmailSent;
  final bool resetEmailSent;
  final bool passwordResetCompleted;
  final AppFailure? error;

  AuthState copyWith({
    bool? isAuthenticated,
    String? userEmail,
    String? displayName,
    bool? isLoading,
    bool? verificationEmailSent,
    bool? resetEmailSent,
    bool? passwordResetCompleted,
    AppFailure? error,
    bool clearError = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userEmail: userEmail ?? this.userEmail,
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      verificationEmailSent:
          verificationEmailSent ?? this.verificationEmailSent,
      resetEmailSent: resetEmailSent ?? this.resetEmailSent,
      passwordResetCompleted:
          passwordResetCompleted ?? this.passwordResetCompleted,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// ViewModel for the Phase 2 Auth flow (Firebase Auth wired in Phase 4).
class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  void signInWithEmail(String email, String password) {
    final String cleanEmail = email.trim();
    if (!_isValidEmail(cleanEmail) || password.length < 6) {
      state = state.copyWith(
        error: const AppFailure.validation(
          message: 'Enter a valid email and a password of at least 6 chars.',
        ),
      );
      return;
    }
    state = AuthState(
      isAuthenticated: true,
      userEmail: cleanEmail,
      displayName: cleanEmail.split('@').first,
    );
  }

  void signUpWithEmail(String email, String password, String displayName) {
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
      return;
    }
    state = AuthState(
      isAuthenticated: true,
      userEmail: cleanEmail,
      displayName: cleanName,
      verificationEmailSent: true,
    );
  }

  void signInWithGoogle() {
    state = const AuthState(
      isAuthenticated: true,
      userEmail: 'listener@peksoft.dev',
      displayName: 'Google Listener',
    );
  }

  void resendVerificationEmail() {
    state = state.copyWith(verificationEmailSent: true, clearError: true);
  }

  void sendPasswordReset(String email) {
    final String cleanEmail = email.trim();
    if (!_isValidEmail(cleanEmail)) {
      state = state.copyWith(
        error: const AppFailure.validation(
          message: 'Enter a valid email address.',
        ),
      );
      return;
    }
    state = state.copyWith(
      userEmail: cleanEmail,
      resetEmailSent: true,
      clearError: true,
    );
  }

  void confirmPasswordReset(String code, String newPassword) {
    if (code.trim().isEmpty || newPassword.length < 6) {
      state = state.copyWith(
        error: const AppFailure.validation(
          message: 'Enter the reset code and a 6+ character password.',
        ),
      );
      return;
    }
    state = state.copyWith(passwordResetCompleted: true, clearError: true);
  }

  void signOut() {
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  static bool _isValidEmail(String email) =>
      email.contains('@') && email.contains('.');
}

final NotifierProvider<AuthViewModel, AuthState> authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
