'use client';

import { AnimatedBackground } from '@/components/motion-primitives/animated-background';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { TRANSITION_FAST } from '@/lib/motion';

export type StationSort = 'popular' | 'trending' | 'name';

export interface StationFilterState {
  workingOnly: boolean;
  httpsOnly: boolean;
  sort: StationSort;
  genre: string | null;
}

const constGenres = ['afrobeats', 'jazz', 'news', 'electronic'] as const;

export function FilterBar({
  value,
  onChange,
  genres = constGenres,
}: {
  value: StationFilterState;
  onChange: (next: StationFilterState) => void;
  genres?: readonly string[];
}) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-border bg-card p-3">
      <div className="flex flex-wrap items-center gap-3">
        <label className="flex cursor-pointer items-center gap-2 text-sm font-medium">
          <Switch
            checked={value.workingOnly}
            onCheckedChange={(checked) =>
              onChange({ ...value, workingOnly: checked })
            }
            aria-label="Working now filter"
          />
          <span>Working now</span>
        </label>

        <Button
          type="button"
          size="sm"
          variant={value.httpsOnly ? 'signal' : 'outline'}
          onClick={() => onChange({ ...value, httpsOnly: !value.httpsOnly })}
        >
          HTTPS playable
        </Button>

        <div className="flex flex-wrap items-center gap-1.5">
          <button
            type="button"
            onClick={() => onChange({ ...value, genre: null })}
            className="rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          >
            <Badge variant={value.genre === null ? 'default' : 'outline'}>
              All genres
            </Badge>
          </button>
          {genres.map((genre) => (
            <button
              key={genre}
              type="button"
              onClick={() =>
                onChange({
                  ...value,
                  genre: value.genre === genre ? null : genre,
                })
              }
              className="rounded-full focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              <Badge variant={value.genre === genre ? 'default' : 'outline'}>
                {genre}
              </Badge>
            </button>
          ))}
        </div>
      </div>

      <div className="inline-flex rounded-lg border border-border bg-muted p-0.5">
        <AnimatedBackground
          defaultValue={value.sort}
          onValueChange={(id) => {
            if (id === 'popular' || id === 'trending' || id === 'name') {
              onChange({ ...value, sort: id });
            }
          }}
          className="rounded-md bg-card shadow-sm"
          transition={TRANSITION_FAST}
        >
          {(
            [
              { id: 'popular', label: 'Popular' },
              { id: 'trending', label: 'Trending' },
              { id: 'name', label: 'A–Z' },
            ] as const
          ).map((item) => (
            <button
              key={item.id}
              data-id={item.id}
              type="button"
              onClick={() => onChange({ ...value, sort: item.id })}
              className="px-3 py-1 text-xs font-medium text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              {item.label}
            </button>
          ))}
        </AnimatedBackground>
      </div>
    </div>
  );
}
