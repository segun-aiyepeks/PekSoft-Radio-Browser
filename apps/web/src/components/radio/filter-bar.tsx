'use client';

import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group';

export type StationSort = 'popular' | 'trending' | 'name';

export interface StationFilterState {
  workingOnly: boolean;
  httpsOnly: boolean;
  sort: StationSort;
  genre: string | null;
}

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

      <ToggleGroup
        value={[value.sort]}
        onValueChange={(vals) => {
          const next = vals[0] as StationSort | undefined;
          if (next) onChange({ ...value, sort: next });
        }}
      >
        <ToggleGroupItem value="popular">Popular</ToggleGroupItem>
        <ToggleGroupItem value="trending">Trending</ToggleGroupItem>
        <ToggleGroupItem value="name">A–Z</ToggleGroupItem>
      </ToggleGroup>
    </div>
  );
}

const constGenres = ['afrobeats', 'jazz', 'news', 'electronic'] as const;
