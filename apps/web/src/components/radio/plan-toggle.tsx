'use client';

import { Badge } from '@/components/ui/badge';
import { cn } from '@/lib/utils';

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
      className="inline-flex items-center gap-1 rounded-xl border border-border bg-muted p-1"
    >
      <button
        type="button"
        role="radio"
        aria-checked={value === 'monthly'}
        onClick={() => onChange('monthly')}
        className={cn(
          'rounded-lg px-4 py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
          value === 'monthly'
            ? 'bg-card text-foreground shadow-sm'
            : 'text-muted-foreground hover:text-foreground',
        )}
      >
        Monthly
      </button>
      <button
        type="button"
        role="radio"
        aria-checked={value === 'annual'}
        onClick={() => onChange('annual')}
        className={cn(
          'flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring',
          value === 'annual'
            ? 'bg-card text-foreground shadow-sm'
            : 'text-muted-foreground hover:text-foreground',
        )}
      >
        <span>Annual</span>
        <Badge variant="default" className="text-[10px]">
          Save 33%
        </Badge>
      </button>
    </div>
  );
}
