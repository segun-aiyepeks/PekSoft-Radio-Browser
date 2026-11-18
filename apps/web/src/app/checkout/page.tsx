'use client';

import { Suspense, useState } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { Loader2, Lock, ShieldCheck } from 'lucide-react';
import { FEATURE_FLAGS, type BillingPlanPeriod } from '@peksoft/shared';
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
import { initializePaystackCheckout } from '@/lib/billing-api';

function CheckoutContent() {
  const searchParams = useSearchParams();
  const initialPeriod: BillingPlanPeriod =
    searchParams.get('period') === 'monthly' ? 'monthly' : 'annual';

  const { user, getIdToken } = useAuth();
  const [period, setPeriod] = useState<BillingPlanPeriod>(initialPeriod);
  const [submitting, setSubmitting] = useState(false);

  const amount = period === 'annual' ? '₦12,000 / year' : '₦1,500 / month';

  const handlePaystack = async () => {
    if (!user) {
      toast.info('Please sign in first to link Plus to your account.');
      return;
    }
    setSubmitting(true);
    try {
      const token = await getIdToken();
      if (!token) throw new Error('Missing auth token');
      const callbackUrl = `${window.location.origin}/checkout/callback`;
      const { authorizationUrl } = await initializePaystackCheckout(token, {
        period,
        callbackUrl,
      });
      window.location.assign(authorizationUrl);
    } catch (err) {
      toast.error(
        err instanceof Error ? err.message : 'Unable to start Paystack checkout.',
      );
      setSubmitting(false);
    }
  };

  return (
    <div className="mx-auto max-w-lg space-y-6 py-4">
      <div>
        <Badge variant="outline" className="mb-2">
          PAYSTACK TEST MODE
        </Badge>
        <h1 className="font-heading text-3xl font-bold tracking-tight">
          Checkout — PekSoft Plus
        </h1>
        <p className="text-sm text-muted-foreground">
          Complete your subscription securely via Paystack.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Select Billing Period</CardTitle>
          <CardDescription>
            Cancel anytime from Account &amp; Settings.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant={period === 'monthly' ? 'signal' : 'outline'}
              onClick={() => setPeriod('monthly')}
            >
              Monthly · ₦1,500
            </Button>
            <Button
              type="button"
              variant={period === 'annual' ? 'signal' : 'outline'}
              onClick={() => setPeriod('annual')}
            >
              Annual · ₦12,000
            </Button>
          </div>

          <div className="rounded-xl border border-border bg-muted/40 p-4 text-sm">
            <div className="flex items-center justify-between font-medium">
              <span>PekSoft Plus ({period})</span>
              <span>{amount}</span>
            </div>
            <p className="mt-2 text-xs text-muted-foreground">
              Cross-platform Android unlock:{' '}
              <strong>
                {FEATURE_FLAGS.crossPlatformEntitlements ? 'ON' : 'OFF'}
              </strong>{' '}
              (web purchases unlock web features until Google Play policy
              confirmation).
            </p>
          </div>

          {!user ? (
            <Link href="/auth" className="block">
              <Button variant="signal" size="lg" className="w-full">
                Sign In to Continue
              </Button>
            </Link>
          ) : (
            <Button
              type="button"
              variant="signal"
              size="lg"
              className="w-full"
              disabled={submitting}
              onClick={handlePaystack}
            >
              {submitting ? (
                <Loader2 className="size-4 animate-spin" />
              ) : (
                <Lock className="size-4" />
              )}
              Pay {amount} with Paystack
            </Button>
          )}

          <p className="flex items-center justify-center gap-1.5 text-xs text-muted-foreground">
            <ShieldCheck className="size-3.5 text-[var(--color-success)]" />
            Secured by Paystack · Test keys only
          </p>
        </CardContent>
      </Card>
    </div>
  );
}

export default function CheckoutPage() {
  return (
    <AppShell>
      <Suspense fallback={<div className="py-12 text-center text-sm text-muted-foreground">Loading checkout…</div>}>
        <CheckoutContent />
      </Suspense>
    </AppShell>
  );
}
