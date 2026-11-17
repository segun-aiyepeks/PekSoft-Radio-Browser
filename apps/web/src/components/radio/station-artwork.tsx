'use client';

import { useState } from 'react';
import { cn } from '@/lib/utils';

const PALETTES = [
  'from-amber-500/80 to-orange-700/80',
  'from-sky-500/80 to-indigo-700/80',
  'from-emerald-500/80 to-teal-700/80',
  'from-fuchsia-500/80 to-purple-700/80',
  'from-rose-500/80 to-pink-700/80',
];

function initialsFor(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return 'FM';
  if (words.length === 1) return (words[0] ?? 'FM').slice(0, 2).toUpperCase();
  return `${words[0]?.[0] ?? ''}${words[1]?.[0] ?? ''}`.toUpperCase();
}

function paletteFor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i += 1) {
    hash = (hash * 31 + name.charCodeAt(i)) | 0;
  }
  return PALETTES[Math.abs(hash) % PALETTES.length] ?? PALETTES[0]!;
}

export function StationArtwork({
  name,
  faviconUrl,
  size = 'md',
  className,
}: {
  name: string;
  faviconUrl: string | null;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}) {
  const [imgError, setImgError] = useState(false);

  const sizeClass = {
    sm: 'size-10 text-xs rounded-lg',
    md: 'size-12 text-sm rounded-xl',
    lg: 'size-16 text-base rounded-2xl',
    xl: 'size-28 text-2xl rounded-2xl',
  }[size];

  if (faviconUrl && !imgError) {
    return (
      <img
        src={faviconUrl}
        alt={`${name} logo`}
        onError={() => setImgError(true)}
        className={cn(
          'shrink-0 border border-border bg-muted object-cover',
          sizeClass,
          className,
        )}
      />
    );
  }

  return (
    <div
      aria-hidden="true"
      className={cn(
        'flex shrink-0 items-center justify-center border border-white/10 bg-gradient-to-br font-heading font-bold text-white shadow-inner',
        paletteFor(name),
        sizeClass,
        className,
      )}
    >
      {initialsFor(name)}
    </div>
  );
}
