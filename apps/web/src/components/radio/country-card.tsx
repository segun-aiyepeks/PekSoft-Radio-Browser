import Link from 'next/link';
import { ChevronRight } from 'lucide-react';
import { CountryFlag } from '@/components/radio/country-flag';
import { Card, CardContent } from '@/components/ui/card';
import type { WebCountry } from '@/lib/mock-data';

export function CountryCard({ country }: { country: WebCountry }) {
  return (
    <Link
      href={`/country/${country.code.toLowerCase()}`}
      className="group block rounded-xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
    >
      <Card className="h-full border-border bg-card transition-colors group-hover:bg-muted/40">
        <CardContent className="flex items-center justify-between gap-3 p-4">
          <div className="flex min-w-0 items-center gap-3">
            <CountryFlag
              code={country.code}
              name={country.name}
              emojiFallback={country.flag}
              size="md"
            />
            <div className="min-w-0">
              <div className="flex items-center gap-2">
                <p className="truncate font-heading text-sm font-bold text-foreground">
                  {country.name}
                </p>
                <span className="rounded bg-muted px-1.5 py-0.5 text-[10px] font-medium text-muted-foreground">
                  {country.stationCount}
                </span>
              </div>
              <p className="mt-0.5 text-xs text-muted-foreground">
                <span className="text-[#10B981]">●</span>{' '}
                {country.workingCount} working streams
              </p>
            </div>
          </div>
          <ChevronRight className="size-4 shrink-0 text-muted-foreground transition-transform group-hover:translate-x-0.5" />
        </CardContent>
      </Card>
    </Link>
  );
}
