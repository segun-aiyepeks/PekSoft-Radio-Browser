'use client';

import { AnimatedBackground } from '@/components/motion-primitives/animated-background';
import { Badge } from '@/components/ui/badge';
import { TRANSITION_NORMAL } from '@/lib/motion';

export type WebBillingPeriod = 'monthly' | 'annual';

export function PlanToggle({
  value,
  onChange,
}: {
  value: WebBillingPeriod;
  onChange: (next: WebBillingPeriod) => void;
}) {
  return (
    <div
      role="radiogroup"
      aria-label="Billing interval"
      className="inline-flex items-center rounded-xl border border-border bg-muted p-1"
    >
      <AnimatedBackground
        defaultValue={value}
        onValueChange={(id) => {
          if (id === 'monthly' || id === 'annual') {
            onChange(id);
          }
        }}
        className="rounded-lg bg-card shadow-sm"
        transition={TRANSITION_NORMAL}
      >
        <button
          key="monthly"
          data-id="monthly"
          type="button"
          role="radio"
          aria-checked={value === 'monthly'}
          onClick={() => onChange('monthly')}
          className="rounded-lg px-4 py-2 text-sm font-medium text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          Monthly
        </button>
        <button
          key="annual"
          data-id="annual"
          type="button"
          role="radio"
          aria-checked={value === 'annual'}
          onClick={() => onChange('annual')}
          className="flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <span>Annual</span>
          <Badge variant="default" className="text-[10px]">
            Save 33%
          </Badge>
        </button>
      </AnimatedBackground>
    </div>
  );
}
