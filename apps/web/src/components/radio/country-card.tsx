import Link from 'next/link';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent } from '@/components/ui/card';
import type { WebCountry } from '@/lib/mock-data';

export function CountryCard({ country }: { country: WebCountry }) {
  return (
    <Link
      href={`/country/${country.code.toLowerCase()}`}
      className="block rounded-xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    >
      <Card className="h-full border-border bg-card transition-colors hover:border-[var(--color-accent)]/50">
        <CardContent className="flex items-center gap-3.5 p-4">
          <span
            aria-hidden="true"
            className="flex size-11 shrink-0 items-center justify-center rounded-xl bg-muted text-2xl"
          >
            {country.flag}
          </span>
          <div className="min-w-0 flex-1">
            <h3 className="truncate font-heading text-sm font-semibold text-foreground">
              {country.name}
            </h3>
            <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
              <span>{country.stationCount} stations</span>
              <Badge variant="live" className="text-[10px]">
                {country.workingCount} live
              </Badge>
            </div>
          </div>
        </CardContent>
      </Card>
    </Link>
  );
}
