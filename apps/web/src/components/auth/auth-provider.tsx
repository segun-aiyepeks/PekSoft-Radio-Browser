'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  sendEmailVerification,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth';
import { mapFirebaseAuthError } from '@/lib/auth-validation';
import {
  createGoogleProvider,
  getFirebaseAuth,
  isFirebaseConfigured,
} from '@/lib/firebase';
import {
  fetchEntitlements,
  type EntitlementSnapshot,
} from '@/lib/library-api';

export interface AuthContextValue {
  user: User | null;
  loading: boolean;
  isConfigured: boolean;
  isPlus: boolean;
  entitlement: EntitlementSnapshot | null;
  getIdToken: () => Promise<string | null>;
  signInWithGoogle: () => Promise<{ error?: string }>;
  signInWithEmail: (
    email: string,
    password: string,
  ) => Promise<{ error?: string }>;
  signUpWithEmail: (
    email: string,
    password: string,
  ) => Promise<{ error?: string; verificationSent?: boolean }>;
  resendVerificationEmail: () => Promise<{ error?: string }>;
  sendPasswordReset: (email: string) => Promise<{ error?: string }>;
  signOut: () => Promise<void>;
  refreshEntitlement: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [entitlement, setEntitlement] = useState<EntitlementSnapshot | null>(
    null,
  );
  const configured = isFirebaseConfigured();

  const refreshEntitlementForUser = useCallback(async (u: User | null) => {
    if (!u) {
      setEntitlement(null);
      return;
    }
    try {
      const token = await u.getIdToken();
      const snap = await fetchEntitlements(token);
      if (snap) {
        setEntitlement(snap);
      }
    } catch {
      // Keep current entitlement state on transient errors
    }
  }, []);

  useEffect(() => {
    const auth = getFirebaseAuth();
    if (!auth) {
      setLoading(false);
      return;
    }

    const unsubscribe = onAuthStateChanged(auth, (nextUser) => {
      setUser(nextUser);
      setLoading(false);
      void refreshEntitlementForUser(nextUser);
    });

    return () => unsubscribe();
  }, [refreshEntitlementForUser]);

  const getIdToken = useCallback(async (): Promise<string | null> => {
    if (!user) return null;
    try {
      return await user.getIdToken();
    } catch {
      return null;
    }
  }, [user]);

  const signInWithGoogle = useCallback(async () => {
    const auth = getFirebaseAuth();
    if (!auth) {
      return { error: 'Firebase Web SDK is not configured in this environment.' };
    }
    try {
      await signInWithPopup(auth, createGoogleProvider());
      return {};
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      return { error: mapFirebaseAuthError(msg) };
    }
  }, []);

  const signInWithEmail = useCallback(
    async (email: string, password: string) => {
      const auth = getFirebaseAuth();
      if (!auth) {
        return { error: 'Firebase Web SDK is not configured in this environment.' };
      }
      try {
        await signInWithEmailAndPassword(auth, email.trim(), password);
        return {};
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        return { error: mapFirebaseAuthError(msg) };
      }
    },
    [],
  );

  const signUpWithEmail = useCallback(
    async (email: string, password: string) => {
      const auth = getFirebaseAuth();
      if (!auth) {
        return { error: 'Firebase Web SDK is not configured in this environment.' };
      }
      try {
        const cred = await createUserWithEmailAndPassword(
          auth,
          email.trim(),
          password,
        );
        try {
          await sendEmailVerification(cred.user);
        } catch {
          // Non-fatal if verification email rate-limited
        }
        return { verificationSent: true };
      } catch (err) {
        const msg = err instanceof Error ? err.message : String(err);
        return { error: mapFirebaseAuthError(msg) };
      }
    },
    [],
  );

  const resendVerificationEmail = useCallback(async () => {
    if (!user) return { error: 'Not signed in.' };
    try {
      await sendEmailVerification(user);
      return {};
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      return { error: mapFirebaseAuthError(msg) };
    }
  }, [user]);

  const sendPasswordReset = useCallback(async (email: string) => {
    const auth = getFirebaseAuth();
    if (!auth) {
      return { error: 'Firebase Web SDK is not configured in this environment.' };
    }
    try {
      await sendPasswordResetEmail(auth, email.trim());
      return {};
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      return { error: mapFirebaseAuthError(msg) };
    }
  }, []);

  const signOut = useCallback(async () => {
    const auth = getFirebaseAuth();
    if (!auth) return;
    await firebaseSignOut(auth);
    setEntitlement(null);
  }, []);

  const refreshEntitlement = useCallback(async () => {
    await refreshEntitlementForUser(user);
  }, [refreshEntitlementForUser, user]);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      loading,
      isConfigured: configured,
      isPlus: entitlement?.isPlus ?? false,
      entitlement,
      getIdToken,
      signInWithGoogle,
      signInWithEmail,
      signUpWithEmail,
      resendVerificationEmail,
      sendPasswordReset,
      signOut,
      refreshEntitlement,
    }),
    [
      user,
      loading,
      configured,
      entitlement,
      getIdToken,
      signInWithGoogle,
      signInWithEmail,
      signUpWithEmail,
      resendVerificationEmail,
      sendPasswordReset,
      signOut,
      refreshEntitlement,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) {
    throw new Error('useAuth must be used inside AuthProvider');
  }
  return ctx;
}
