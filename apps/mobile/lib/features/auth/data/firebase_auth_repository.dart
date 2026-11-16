import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:peksoft_radio/core/domain/app_failure.dart';
import 'package:peksoft_radio/core/domain/result.dart';
import 'package:peksoft_radio/features/auth/domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      emailVerified: user.emailVerified,
      providerIds: user.providerData
          .map((UserInfo info) => info.providerId)
          .toList(growable: false),
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<Result<AuthUser>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = credential.user;
      if (user == null) {
        return const Failure<AuthUser>(
          AppFailure.validation(
            message: 'Account creation did not return a user.',
          ),
        );
      }
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
      }
      await user.sendEmailVerification();
      await user.reload();
      return Success<AuthUser>(_mapUser(_auth.currentUser ?? user)!);
    } on FirebaseAuthException catch (e) {
      return Failure<AuthUser>(_mapFirebaseError(e));
    } catch (e) {
      return Failure<AuthUser>(
        AppFailure.unknown(message: e.toString(), cause: e),
      );
    }
  }

  @override
  Future<Result<AuthOutcome>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final AuthUser? user = _mapUser(credential.user);
      if (user == null) {
        return const Failure<AuthOutcome>(
          AppFailure.validation(message: 'Sign-in did not return a user.'),
        );
      }
      return Success<AuthOutcome>(AuthSuccess(user));
    } on FirebaseAuthException catch (e) {
      return Failure<AuthOutcome>(_mapFirebaseError(e));
    } catch (e) {
      return Failure<AuthOutcome>(
        AppFailure.unknown(message: e.toString(), cause: e),
      );
    }
  }

  @override
  Future<Result<AuthOutcome>> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await _googleSignIn.initialize();
        _googleInitialized = true;
      }
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = account.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );
      final AuthUser? user = _mapUser(userCred.user);
      if (user == null) {
        return const Failure<AuthOutcome>(
          AppFailure.validation(
            message: 'Google sign-in did not return a user.',
          ),
        );
      }
      return Success<AuthOutcome>(AuthSuccess(user));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' &&
          e.credential != null &&
          e.email != null) {
        return Success<AuthOutcome>(
          AuthAccountLinkRequired(
            email: e.email!,
            pendingCredential: e.credential!,
          ),
        );
      }
      return Failure<AuthOutcome>(_mapFirebaseError(e));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Failure<AuthOutcome>(
          AppFailure.validation(message: 'Google sign-in was cancelled.'),
        );
      }
      return Failure<AuthOutcome>(
        AppFailure.validation(
          message: e.description ?? 'Google sign-in failed.',
        ),
      );
    } catch (e) {
      return Failure<AuthOutcome>(
        AppFailure.unknown(message: e.toString(), cause: e),
      );
    }
  }

  @override
  Future<Result<AuthUser>> linkPendingCredentialWithPassword({
    required String email,
    required String password,
    required Object pendingCredential,
  }) async {
    try {
      final UserCredential signedIn = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = signedIn.user;
      if (user == null) {
        return const Failure<AuthUser>(
          AppFailure.validation(message: 'Could not sign in to link accounts.'),
        );
      }
      if (pendingCredential is AuthCredential) {
        final UserCredential linked = await user.linkWithCredential(
          pendingCredential,
        );
        return Success<AuthUser>(_mapUser(linked.user ?? user)!);
      }
      return Success<AuthUser>(_mapUser(user)!);
    } on FirebaseAuthException catch (e) {
      return Failure<AuthUser>(_mapFirebaseError(e));
    } catch (e) {
      return Failure<AuthUser>(
        AppFailure.unknown(message: e.toString(), cause: e),
      );
    }
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        return const Failure<void>(
          AppFailure.validation(message: 'No signed-in user to verify.'),
        );
      }
      await user.sendEmailVerification();
      return const Success<void>(null);
    } on FirebaseAuthException catch (e) {
      return Failure<void>(_mapFirebaseError(e));
    } catch (e) {
      return Failure<void>(AppFailure.unknown(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<AuthUser?>> reloadUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return const Success<AuthUser?>(null);
      await user.reload();
      return Success<AuthUser?>(_mapUser(_auth.currentUser));
    } on FirebaseAuthException catch (e) {
      return Failure<AuthUser?>(_mapFirebaseError(e));
    } catch (e) {
      return Failure<AuthUser?>(
        AppFailure.unknown(message: e.toString(), cause: e),
      );
    }
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return const Success<void>(null);
    } on FirebaseAuthException catch (e) {
      return Failure<void>(_mapFirebaseError(e));
    } catch (e) {
      return Failure<void>(AppFailure.unknown(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      if (_googleInitialized) {
        await _googleSignIn.signOut();
      }
      return const Success<void>(null);
    } catch (e) {
      return Failure<void>(AppFailure.unknown(message: e.toString(), cause: e));
    }
  }

  @override
  Future<Result<void>> deleteFirebaseUser() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
      return const Success<void>(null);
    } on FirebaseAuthException catch (e) {
      return Failure<void>(_mapFirebaseError(e));
    } catch (e) {
      return Failure<void>(AppFailure.unknown(message: e.toString(), cause: e));
    }
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final User? user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  AppFailure _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AppFailure.validation(
          message: 'Please enter a valid email address.',
        );
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return const AppFailure.validation(
          message: 'Incorrect email or password. Please try again.',
        );
      case 'email-already-in-use':
        return const AppFailure.validation(
          message: 'An account with this email already exists.',
        );
      case 'weak-password':
        return const AppFailure.validation(
          message: 'Choose a stronger password (at least 6 characters).',
        );
      case 'requires-recent-login':
        return const AppFailure.validation(
          message:
              'Please sign in again before deleting your account for security.',
        );
      case 'network-request-failed':
        return const AppFailure.network(
          message: 'Network error. Check your connection and try again.',
        );
      default:
        return AppFailure.unknown(
          message: e.message ?? 'Authentication failed (${e.code}).',
          cause: e,
        );
    }
  }
}
