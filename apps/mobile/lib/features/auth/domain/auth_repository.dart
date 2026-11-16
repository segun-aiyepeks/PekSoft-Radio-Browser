import 'package:flutter/foundation.dart';
import 'package:peksoft_radio/core/domain/result.dart';

@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.emailVerified = false,
    this.providerIds = const <String>[],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool emailVerified;
  final List<String> providerIds;
}

sealed class AuthOutcome {
  const AuthOutcome();
}

final class AuthSuccess extends AuthOutcome {
  const AuthSuccess(this.user);
  final AuthUser user;
}

final class AuthAccountLinkRequired extends AuthOutcome {
  const AuthAccountLinkRequired({
    required this.email,
    required this.pendingCredential,
  });

  final String email;
  final Object pendingCredential;
}

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  AuthUser? get currentUser;

  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Result<AuthOutcome>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<AuthOutcome>> signInWithGoogle();

  Future<Result<AuthUser>> linkPendingCredentialWithPassword({
    required String email,
    required String password,
    required Object pendingCredential,
  });

  Future<Result<void>> sendEmailVerification();

  Future<Result<AuthUser?>> reloadUser();

  Future<Result<void>> sendPasswordResetEmail(String email);

  Future<Result<void>> signOut();

  Future<Result<void>> deleteFirebaseUser();

  Future<String?> getIdToken({bool forceRefresh = false});
}
