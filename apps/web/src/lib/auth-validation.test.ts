import { describe, expect, it } from 'vitest';
import {
  mapFirebaseAuthError,
  validateAuthForm,
  validateEmail,
  validatePassword,
} from './auth-validation';

describe('auth-validation', () => {
  it('validates email addresses', () => {
    expect(validateEmail('')).toBe('Email address is required.');
    expect(validateEmail('not-an-email')).toBe('Enter a valid email address.');
    expect(validateEmail('listener@peksoft.com')).toBeUndefined();
  });

  it('validates passwords for signin and signup', () => {
    expect(validatePassword('')).toBe('Password is required.');
    expect(validatePassword('12345', true)).toBe(
      'Password must be at least 6 characters.',
    );
    expect(validatePassword('12345', false)).toBeUndefined();
    expect(validatePassword('123456', true)).toBeUndefined();
  });

  it('validates confirmPassword in signup mode and skips password in reset mode', () => {
    expect(
      validateAuthForm({
        mode: 'signup',
        email: 'a@b.com',
        password: 'password1',
        confirmPassword: 'password2',
      }),
    ).toEqual({ confirmPassword: 'Passwords do not match.' });

    expect(
      validateAuthForm({
        mode: 'reset',
        email: 'a@b.com',
      }),
    ).toEqual({});
  });

  it('maps Firebase error codes to user-friendly messages', () => {
    expect(mapFirebaseAuthError('Firebase: Error (auth/invalid-credential).')).toBe(
      'Incorrect email or password. Please try again.',
    );
    expect(mapFirebaseAuthError('auth/email-already-in-use')).toBe(
      'An account with this email already exists. Try signing in.',
    );
    expect(mapFirebaseAuthError('unknown-error')).toBe(
      'Authentication failed. Please try again.',
    );
  });
});
