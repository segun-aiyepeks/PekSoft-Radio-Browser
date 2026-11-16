import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';
import { getAuth, type Auth } from 'firebase-admin/auth';
import { unauthorized } from '../errors/app-error.js';

export interface VerifiedIdentity {
  uid: string;
  email?: string;
  emailVerified: boolean;
  displayName?: string;
}

/**
 * Abstraction over Firebase Admin Auth so token verification and account deletion
 * can be mocked cleanly in unit/integration tests.
 */
export interface AuthProvider {
  verifyIdToken(idToken: string): Promise<VerifiedIdentity>;
  deleteUser(uid: string): Promise<void>;
}

export interface FirebaseConfig {
  projectId?: string;
  clientEmail?: string;
  privateKey?: string;
}

export class FirebaseAuthProvider implements AuthProvider {
  private readonly auth: Auth;

  constructor(config: FirebaseConfig) {
    let app: App;
    const existing = getApps().find((a) => a.name === 'peksoft-api');
    if (existing) {
      app = existing;
    } else if (config.projectId && config.clientEmail && config.privateKey) {
      app = initializeApp(
        {
          credential: cert({
            projectId: config.projectId,
            clientEmail: config.clientEmail,
            privateKey: config.privateKey.replace(/\\n/g, '\n'),
          }),
        },
        'peksoft-api',
      );
    } else if (config.projectId) {
      app = initializeApp({ projectId: config.projectId }, 'peksoft-api');
    } else {
      throw new Error(
        'Firebase Admin requires FIREBASE_PROJECT_ID (and service account credentials in production).',
      );
    }
    this.auth = getAuth(app);
  }

  async verifyIdToken(idToken: string): Promise<VerifiedIdentity> {
    try {
      const decoded = await this.auth.verifyIdToken(idToken, true);
      return {
        uid: decoded.uid,
        ...(decoded.email ? { email: decoded.email } : {}),
        emailVerified: Boolean(decoded.email_verified),
        ...(typeof decoded.name === 'string' && decoded.name.length > 0
          ? { displayName: decoded.name }
          : {}),
      };
    } catch {
      throw unauthorized('Invalid or expired authentication token');
    }
  }

  async deleteUser(uid: string): Promise<void> {
    try {
      await this.auth.deleteUser(uid);
    } catch (err) {
      const code = (err as { code?: string }).code;
      if (code === 'auth/user-not-found') {
        return;
      }
      throw err;
    }
  }
}
