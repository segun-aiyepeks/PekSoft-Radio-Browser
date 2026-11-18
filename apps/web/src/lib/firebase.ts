import { initializeApp, getApps, getApp, type FirebaseApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, type Auth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY ?? '',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN ?? '',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID ?? '',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID ?? '',
};

export function isFirebaseConfigured(): boolean {
  return Boolean(
    firebaseConfig.apiKey &&
      firebaseConfig.authDomain &&
      firebaseConfig.projectId,
  );
}

let cachedApp: FirebaseApp | null = null;
let cachedAuth: Auth | null = null;

export function getFirebaseAuth(): Auth | null {
  if (typeof window === 'undefined' || !isFirebaseConfigured()) {
    return null;
  }
  if (!cachedApp) {
    cachedApp =
      getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
  }
  if (!cachedAuth) {
    cachedAuth = getAuth(cachedApp);
  }
  return cachedAuth;
}

export function createGoogleProvider(): GoogleAuthProvider {
  const provider = new GoogleAuthProvider();
  provider.setCustomParameters({ prompt: 'select_account' });
  return provider;
}
