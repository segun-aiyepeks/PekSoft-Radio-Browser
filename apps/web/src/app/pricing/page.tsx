'use client';

import { useState } from 'react';
import { Check } from 'lucide-react';
import { toast } from 'sonner';
import { PLAN_FEATURE_GATES } from '@peksoft/shared';
import { AppShell } from '@/components/radio/app-shell';
import {
  PlanToggle,
  type WebBillingPeriod,
} from '@/components/radio/plan-toggle';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';

export default function PricingPage() {
  const [period, setPeriod] = useState<WebBillingPeriod>('annual');
  const free = PLAN_FEATURE_GATES.FREE;
  const plus = PLAN_FEATURE_GATES.PLUS;

  const priceText = period === 'annual' ? '₦12,000 / year' : '₦1,500 / month';

  const rows: Array<{ feature: string; free: string; plus: string }> = [
    { feature: 'Browse & play every station worldwide', free: 'Yes', plus: 'Yes' },
    { feature: 'Ads', free: free.adsEnabled ? 'Yes' : 'None', plus: plus.adsEnabled ? 'Yes' : 'None' },
    { feature: 'Favourites', free: `Up to ${free.maxFavorites}`, plus: 'Unlimited' },
    { feature: 'Collections', free: `${free.maxCollections}`, plus: 'Unlimited' },
    { feature: 'Recently played', free: `Last ${free.maxRecentlyPlayed}`, plus: `Last ${plus.maxRecentlyPlayed}` },
    { feature: 'Song history', free: `Last ${free.maxSongHistory}`, plus: 'Unlimited' },
    { feature: 'Sleep timer', free: 'Presets', plus: 'Custom + fade-out' },
    { feature: 'Advanced filters (bitrate, codec, HTTPS)', free: 'No', plus: 'Yes' },
  ];

  return (
    <AppShell>
      <div className="space-y-8">
        <div className="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center">
          <div>
            <Badge variant="default" className="mb-2">
              PEKSOFT PLUS
            </Badge>
            <h1 className="font-heading text-3xl font-bold tracking-tight">
              Simple, honest pricing
            </h1>
            <p className="text-sm text-muted-foreground">
              Every radio station stays free forever. Plus adds ad-free
              listening and unlimited power features.
            </p>
          </div>
          <PlanToggle value={period} onChange={setPeriod} />
        </div>

        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Free</CardTitle>
              <CardDescription>
                Open global discovery with up to 30 favourites.
              </CardDescription>
              <p className="pt-2 font-heading text-3xl font-bold">₦0</p>
            </CardHeader>
            <CardContent className="space-y-3 text-sm text-muted-foreground">
              <p>Includes worldwide stations, basic search, and 2 collections.</p>
            </CardContent>
          </Card>

          <Card className="border-[var(--color-accent)]">
            <CardHeader>
              <CardTitle>PekSoft Plus</CardTitle>
              <CardDescription>
                Ad-free listening, unlimited library, and power controls.
              </CardDescription>
              <p className="pt-2 font-heading text-3xl font-bold text-[var(--color-accent)]">
                {priceText}
              </p>
            </CardHeader>
            <CardContent className="space-y-4">
              <ul className="space-y-2 text-sm">
                {[
                  'Zero banner or audio ads',
                  'Unlimited favourites, collections & song history',
                  'Custom sleep timer with fade-out',
                  'Bitrate, codec & HTTPS-only filters',
                ].map((benefit) => (
                  <li key={benefit} className="flex items-center gap-2">
                    <Check className="size-4 text-[var(--color-success)]" />
                    <span>{benefit}</span>
                  </li>
                ))}
              </ul>
              <Button
                variant="signal"
                size="lg"
                className="w-full"
                onClick={() =>
                  toast.info('Paystack checkout will be wired in Milestone 6.8')
                }
              >
                Upgrade to Plus ({priceText})
              </Button>
            </CardContent>
          </Card>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Free vs Plus Comparison</CardTitle>
          </CardHeader>
          <CardContent className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead>
                <tr className="border-b border-border text-xs uppercase text-muted-foreground">
                  <th className="py-2 pr-4">Feature</th>
                  <th className="py-2 pr-4">Free</th>
                  <th className="py-2">Plus</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row) => (
                  <tr key={row.feature} className="border-b border-border/60">
                    <td className="py-2.5 pr-4 font-medium">{row.feature}</td>
                    <td className="py-2.5 pr-4 text-muted-foreground">
                      {row.free}
                    </td>
                    <td className="py-2.5 font-semibold text-[var(--color-accent)]">
                      {row.plus}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </CardContent>
        </Card>
      </div>
    </AppShell>
  );
}
