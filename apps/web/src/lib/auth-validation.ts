export interface AuthFieldErrors {
  email?: string;
  password?: string;
  confirmPassword?: string;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateEmail(email: string): string | undefined {
  const trimmed = email.trim();
  if (!trimmed) return 'Email address is required.';
  if (!EMAIL_RE.test(trimmed)) return 'Enter a valid email address.';
  return undefined;
}

export function validatePassword(
  password: string,
  requireStrong = false,
): string | undefined {
  if (!password) return 'Password is required.';
  if (requireStrong && password.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return undefined;
}

export function validateAuthForm(params: {
  mode: 'signin' | 'signup' | 'reset';
  email: string;
  password?: string;
  confirmPassword?: string;
}): AuthFieldErrors {
  const errors: AuthFieldErrors = {};
  const emailErr = validateEmail(params.email);
  if (emailErr) errors.email = emailErr;

  if (params.mode !== 'reset') {
    const passErr = validatePassword(
      params.password ?? '',
      params.mode === 'signup',
    );
    if (passErr) errors.password = passErr;
  }

  if (
    params.mode === 'signup' &&
    params.confirmPassword !== undefined &&
    params.password !== params.confirmPassword
  ) {
    errors.confirmPassword = 'Passwords do not match.';
  }

  return errors;
}

export function mapFirebaseAuthError(codeOrMessage: string): string {
  if (codeOrMessage.includes('auth/invalid-credential')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (codeOrMessage.includes('auth/user-not-found')) {
    return 'No account found with that email address.';
  }
  if (codeOrMessage.includes('auth/wrong-password')) {
    return 'Incorrect password. Please try again.';
  }
  if (codeOrMessage.includes('auth/email-already-in-use')) {
    return 'An account with this email already exists. Try signing in.';
  }
  if (codeOrMessage.includes('auth/weak-password')) {
    return 'Password is too weak. Use at least 6 characters.';
  }
  if (codeOrMessage.includes('auth/too-many-requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (codeOrMessage.includes('auth/popup-closed-by-user')) {
    return 'Google sign-in was cancelled before completing.';
  }
  if (codeOrMessage.includes('auth/network-request-failed')) {
    return 'Network error. Check your connection and try again.';
  }
  return 'Authentication failed. Please try again.';
}
