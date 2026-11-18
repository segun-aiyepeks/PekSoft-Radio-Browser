'use client';

import { useState } from 'react';
import Link from 'next/link';
import { CheckCircle2, Loader2, MailCheck, ShieldAlert } from 'lucide-react';
import { AnimatePresence, motion } from 'motion/react';
import { toast } from 'sonner';
import { useAuth } from '@/components/auth/auth-provider';
import { AppShell } from '@/components/radio/app-shell';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Separator } from '@/components/ui/separator';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  validateAuthForm,
  type AuthFieldErrors,
} from '@/lib/auth-validation';
import { TRANSITION_FAST } from '@/lib/motion';

function AnimatedFieldError({
  id,
  message,
}: {
  id: string;
  message?: string;
}) {
  return (
    <AnimatePresence mode="wait">
      {message ? (
        <motion.p
          key={message}
          id={id}
          role="alert"
          initial={{ opacity: 0, y: -4 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -4 }}
          transition={TRANSITION_FAST}
          className="text-xs font-medium text-destructive"
        >
          {message}
        </motion.p>
      ) : null}
    </AnimatePresence>
  );
}

export default function AuthPage() {
  const {
    user,
    isConfigured,
    signInWithGoogle,
    signInWithEmail,
    signUpWithEmail,
    resendVerificationEmail,
    sendPasswordReset,
    signOut,
  } = useAuth();

  const [mode, setMode] = useState<'signin' | 'signup' | 'reset'>('signin');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [errors, setErrors] = useState<AuthFieldErrors>({});
  const [formBanner, setFormBanner] = useState<{
    type: 'error' | 'success';
    text: string;
  } | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const handleModeChange = (next: string) => {
    if (next === 'signin' || next === 'signup' || next === 'reset') {
      setMode(next);
      setErrors({});
      setFormBanner(null);
    }
  };

  const handleGoogle = async () => {
    setFormBanner(null);
    setSubmitting(true);
    const res = await signInWithGoogle();
    setSubmitting(false);
    if (res.error) {
      setFormBanner({ type: 'error', text: res.error });
    } else {
      toast.success('Signed in with Google');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormBanner(null);

    const nextErrors = validateAuthForm({
      mode,
      email,
      password: mode === 'reset' ? undefined : password,
      confirmPassword: mode === 'signup' ? confirmPassword : undefined,
    });
    setErrors(nextErrors);
    if (Object.keys(nextErrors).length > 0) return;

    setSubmitting(true);
    if (mode === 'signin') {
      const res = await signInWithEmail(email, password);
      setSubmitting(false);
      if (res.error) {
        setFormBanner({ type: 'error', text: res.error });
      } else {
        toast.success('Welcome back!');
      }
      return;
    }

    if (mode === 'signup') {
      const res = await signUpWithEmail(email, password);
      setSubmitting(false);
      if (res.error) {
        setFormBanner({ type: 'error', text: res.error });
      } else {
        setFormBanner({
          type: 'success',
          text: 'Account created! Check your inbox for a verification email.',
        });
        toast.success('Verification email sent');
      }
      return;
    }

    const res = await sendPasswordReset(email);
    setSubmitting(false);
    if (res.error) {
      setFormBanner({ type: 'error', text: res.error });
    } else {
      setFormBanner({
        type: 'success',
        text: `Password reset link sent to ${email.trim()}.`,
      });
      toast.success('Password reset email sent');
    }
  };

  if (user) {
    return (
      <AppShell>
        <div className="mx-auto max-w-md py-6">
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between gap-2">
                <CardTitle className="font-heading text-2xl">
                  Signed In
                </CardTitle>
                <Badge variant={user.emailVerified ? 'live' : 'outline'}>
                  {user.emailVerified ? 'Verified' : 'Unverified'}
                </Badge>
              </div>
              <CardDescription>
                {user.email ?? user.displayName ?? 'Authenticated listener'}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {!user.emailVerified && (
                <div className="space-y-2 rounded-xl border border-amber-500/40 bg-amber-500/10 p-3 text-xs">
                  <div className="flex items-center gap-2 font-medium text-amber-300">
                    <ShieldAlert className="size-4" /> Verify your email address
                  </div>
                  <p className="text-muted-foreground">
                    Confirm your email to protect your synced library and Plus
                    subscription.
                  </p>
                  <Button
                    type="button"
                    size="sm"
                    variant="outline"
                    onClick={async () => {
                      const res = await resendVerificationEmail();
                      if (res.error) toast.error(res.error);
                      else toast.success('Verification email resent');
                    }}
                  >
                    <MailCheck className="size-4" /> Resend verification email
                  </Button>
                </div>
              )}

              <div className="flex flex-col gap-2">
                <Link href="/library">
                  <Button variant="signal" className="w-full">
                    Open My Library
                  </Button>
                </Link>
                <Button
                  type="button"
                  variant="outline"
                  className="w-full"
                  onClick={() => void signOut()}
                >
                  Sign Out
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </AppShell>
    );
  }

  return (
    <AppShell>
      <div className="mx-auto max-w-md py-6">
        <Card>
          <CardHeader>
            <CardTitle className="font-heading text-2xl">
              Welcome to PekSoft Radio
            </CardTitle>
            <CardDescription>
              Sync your favourites, collections, and Plus subscription across
              devices.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-5">
            {!isConfigured && (
              <div className="rounded-xl border border-border bg-muted/40 p-3 text-xs text-muted-foreground">
                Firebase Web SDK env keys (
                <code>NEXT_PUBLIC_FIREBASE_*</code>) are not set in this local
                environment. Form validation is active; sign-in activates once
                keys are configured.
              </div>
            )}

            <Button
              type="button"
              variant="outline"
              className="w-full"
              disabled={submitting}
              onClick={handleGoogle}
            >
              Continue with Google
            </Button>

            <div className="flex items-center gap-3 text-xs text-muted-foreground">
              <Separator className="flex-1" />
              <span>OR</span>
              <Separator className="flex-1" />
            </div>

            <AnimatePresence mode="wait">
              {formBanner && (
                <motion.div
                  key={formBanner.text}
                  role="status"
                  initial={{ opacity: 0, y: -6 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -6 }}
                  transition={TRANSITION_FAST}
                  className={
                    formBanner.type === 'error'
                      ? 'flex items-center gap-2 rounded-xl border border-destructive/40 bg-destructive/10 p-3 text-xs text-destructive'
                      : 'flex items-center gap-2 rounded-xl border border-[var(--color-success)]/40 bg-[var(--color-success)]/10 p-3 text-xs text-[var(--color-success)]'
                  }
                >
                  {formBanner.type === 'success' ? (
                    <CheckCircle2 className="size-4 shrink-0" />
                  ) : (
                    <ShieldAlert className="size-4 shrink-0" />
                  )}
                  <span>{formBanner.text}</span>
                </motion.div>
              )}
            </AnimatePresence>

            <Tabs value={mode} onValueChange={handleModeChange}>
              <TabsList className="grid w-full grid-cols-3">
                <TabsTrigger value="signin">Sign In</TabsTrigger>
                <TabsTrigger value="signup">Sign Up</TabsTrigger>
                <TabsTrigger value="reset">Reset</TabsTrigger>
              </TabsList>

              <TabsContent value="signin" className="mt-4">
                <form noValidate onSubmit={handleSubmit} className="space-y-3">
                  <div className="space-y-1">
                    <Input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      aria-label="Email address"
                      aria-invalid={Boolean(errors.email)}
                      aria-describedby={
                        errors.email ? 'signin-email-err' : undefined
                      }
                    />
                    <AnimatedFieldError
                      id="signin-email-err"
                      message={errors.email}
                    />
                  </div>
                  <div className="space-y-1">
                    <Input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Password"
                      aria-label="Password"
                      aria-invalid={Boolean(errors.password)}
                      aria-describedby={
                        errors.password ? 'signin-pass-err' : undefined
                      }
                    />
                    <AnimatedFieldError
                      id="signin-pass-err"
                      message={errors.password}
                    />
                  </div>
                  <Button
                    type="submit"
                    variant="signal"
                    className="w-full"
                    disabled={submitting}
                  >
                    {submitting && <Loader2 className="size-4 animate-spin" />}
                    Sign In with Email
                  </Button>
                </form>
              </TabsContent>

              <TabsContent value="signup" className="mt-4">
                <form noValidate onSubmit={handleSubmit} className="space-y-3">
                  <div className="space-y-1">
                    <Input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      aria-label="Email address"
                      aria-invalid={Boolean(errors.email)}
                      aria-describedby={
                        errors.email ? 'signup-email-err' : undefined
                      }
                    />
                    <AnimatedFieldError
                      id="signup-email-err"
                      message={errors.email}
                    />
                  </div>
                  <div className="space-y-1">
                    <Input
                      type="password"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="Create a password (min 6 chars)"
                      aria-label="New password"
                      aria-invalid={Boolean(errors.password)}
                      aria-describedby={
                        errors.password ? 'signup-pass-err' : undefined
                      }
                    />
                    <AnimatedFieldError
                      id="signup-pass-err"
                      message={errors.password}
                    />
                  </div>
                  <div className="space-y-1">
                    <Input
                      type="password"
                      value={confirmPassword}
                      onChange={(e) => setConfirmPassword(e.target.value)}
                      placeholder="Confirm password"
                      aria-label="Confirm password"
                      aria-invalid={Boolean(errors.confirmPassword)}
                      aria-describedby={
                        errors.confirmPassword ? 'signup-confirm-err' : undefined
                      }
                    />
                    <AnimatedFieldError
                      id="signup-confirm-err"
                      message={errors.confirmPassword}
                    />
                  </div>
                  <Button
                    type="submit"
                    variant="signal"
                    className="w-full"
                    disabled={submitting}
                  >
                    {submitting && <Loader2 className="size-4 animate-spin" />}
                    Create Account
                  </Button>
                </form>
              </TabsContent>

              <TabsContent value="reset" className="mt-4">
                <form noValidate onSubmit={handleSubmit} className="space-y-3">
                  <div className="space-y-1">
                    <Input
                      type="email"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="you@example.com"
                      aria-label="Reset email address"
                      aria-invalid={Boolean(errors.email)}
                      aria-describedby={
                        errors.email ? 'reset-email-err' : undefined
                      }
                    />
                    <AnimatedFieldError
                      id="reset-email-err"
                      message={errors.email}
                    />
                  </div>
                  <Button
                    type="submit"
                    variant="signal"
                    className="w-full"
                    disabled={submitting}
                  >
                    {submitting && <Loader2 className="size-4 animate-spin" />}
                    Send Reset Link
                  </Button>
                </form>
              </TabsContent>
            </Tabs>

            <p className="text-center text-xs text-muted-foreground">
              By continuing you agree to our{' '}
              <Link href="/pricing" className="underline">
                Free &amp; Plus terms
              </Link>
              .
            </p>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
