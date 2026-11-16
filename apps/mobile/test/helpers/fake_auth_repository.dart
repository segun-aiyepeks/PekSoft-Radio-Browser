import 'dart:async';

import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.googleRequiresLink = false,
    this.tokenValue = 'fake-id-token-1',
    this.refreshedTokenValue = 'fake-id-token-2',
  });

  final bool googleRequiresLink;
  final String tokenValue;
  final String refreshedTokenValue;

  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  bool verificationResent = false;
  bool passwordResetSent = false;
  bool signedOutCalled = false;
  bool deletedFirebaseUser = false;
  bool linkedCredentialCalled = false;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final AuthUser user = AuthUser(
      uid: 'uid-signup-1',
      email: email,
      displayName: displayName,
      emailVerified: false,
      providerIds: const <String>['password'],
    );
    _current = user;
    _controller.add(user);
    return Success<AuthUser>(user);
  }

  @override
  Future<Result<AuthOutcome>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (password == 'wrongpass') {
      return const Failure<AuthOutcome>(
        AppFailure.validation(message: 'Incorrect email or password.'),
      );
    }
    final AuthUser user = AuthUser(
      uid: 'uid-email-1',
      email: email,
      displayName: email.split('@').first,
      emailVerified: true,
      providerIds: const <String>['password'],
    );
    _current = user;
    _controller.add(user);
    return Success<AuthOutcome>(AuthSuccess(user));
  }

  @override
  Future<Result<AuthOutcome>> signInWithGoogle() async {
    if (googleRequiresLink) {
      return const Success<AuthOutcome>(
        AuthAccountLinkRequired(
          email: 'shared@example.com',
          pendingCredential: 'fake-google-cred',
        ),
      );
    }
    const AuthUser user = AuthUser(
      uid: 'uid-google-1',
      email: 'google@example.com',
      displayName: 'Google Listener',
      emailVerified: true,
      providerIds: <String>['google.com'],
    );
    _current = user;
    _controller.add(user);
    return const Success<AuthOutcome>(AuthSuccess(user));
  }

  @override
  Future<Result<AuthUser>> linkPendingCredentialWithPassword({
    required String email,
    required String password,
    required Object pendingCredential,
  }) async {
    linkedCredentialCalled = true;
    final AuthUser user = AuthUser(
      uid: 'uid-linked-1',
      email: email,
      displayName: email.split('@').first,
      emailVerified: true,
      providerIds: const <String>['password', 'google.com'],
    );
    _current = user;
    _controller.add(user);
    return Success<AuthUser>(user);
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    verificationResent = true;
    return const Success<void>(null);
  }

  @override
  Future<Result<AuthUser?>> reloadUser() async {
    if (_current != null) {
      _current = AuthUser(
        uid: _current!.uid,
        email: _current!.email,
        displayName: _current!.displayName,
        emailVerified: true,
        providerIds: _current!.providerIds,
      );
      _controller.add(_current);
    }
    return Success<AuthUser?>(_current);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    passwordResetSent = true;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> signOut() async {
    signedOutCalled = true;
    _current = null;
    _controller.add(null);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> deleteFirebaseUser() async {
    deletedFirebaseUser = true;
    _current = null;
    _controller.add(null);
    return const Success<void>(null);
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (_current == null) return null;
    return forceRefresh ? refreshedTokenValue : tokenValue;
  }

  void dispose() {
    _controller.close();
  }
}
