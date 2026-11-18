'use client';

import { Suspense, useEffect, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { CheckCircle2, Loader2, XCircle } from 'lucide-react';
import { useAuth } from '@/components/auth/auth-provider';
import { AppShell } from '@/components/radio/app-shell';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { verifyPaystackCallback } from '@/lib/billing-api';

function CallbackContent() {
  const searchParams = useSearchParams();
  const reference =
    searchParams.get('reference') ?? searchParams.get('trxref');
  const { user, getIdToken, refreshEntitlement } = useAuth();
  const [state, setState] = useState<'verifying' | 'success' | 'error'>(
    'verifying',
  );
  const [message, setMessage] = useState('Verifying your Paystack payment…');

  useEffect(() => {
    if (!reference) {
      setState('error');
      setMessage('Missing Paystack transaction reference.');
      return;
    }
    if (!user) return;

    let cancelled = false;
    void (async () => {
      try {
        const token = await getIdToken();
        if (!token) throw new Error('Not authenticated');
        await verifyPaystackCallback(token, reference);
        await refreshEntitlement();
        if (!cancelled) {
          setState('success');
          setMessage('PekSoft Plus is now active on your account!');
        }
      } catch (err) {
        if (!cancelled) {
          setState('error');
          setMessage(
            err instanceof Error
              ? err.message
              : 'Payment verification failed.',
          );
        }
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [getIdToken, reference, refreshEntitlement, user]);

  return (
    <div className="mx-auto max-w-md py-8">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            {state === 'verifying' && (
              <Loader2 className="size-5 animate-spin text-[var(--color-accent)]" />
            )}
            {state === 'success' && (
              <CheckCircle2 className="size-5 text-[var(--color-success)]" />
            )}
            {state === 'error' && (
              <XCircle className="size-5 text-destructive" />
            )}
            {state === 'verifying'
              ? 'Confirming Payment'
              : state === 'success'
                ? 'Welcome to Plus'
                : 'Verification Issue'}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <p className="text-sm text-muted-foreground">{message}</p>
          <div className="flex gap-2">
            <Link href="/home" className="flex-1">
              <Button variant="signal" className="w-full">
                Start Listening
              </Button>
            </Link>
            <Link href="/account" className="flex-1">
              <Button variant="outline" className="w-full">
                Manage Plan
              </Button>
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

export default function CheckoutCallbackPage() {
  return (
    <AppShell>
      <Suspense fallback={<div className="py-12 text-center text-sm text-muted-foreground">Confirming payment…</div>}>
        <CallbackContent />
      </Suspense>
    </AppShell>
  );
}
