'use client';

import { useState } from 'react';
import { cn } from '@/lib/utils';

export function CountryFlag({
  code,
  name,
  emojiFallback,
  size = 'md',
  className,
}: {
  code: string;
  name?: string;
  emojiFallback?: string;
  size?: 'xs' | 'sm' | 'md' | 'lg';
  className?: string;
}) {
  const [imgError, setImgError] = useState(false);
  const normalized = code.trim().toLowerCase();
  const isValidIso = /^[a-z]{2}$/.test(normalized);

  const sizeClass = {
    xs: 'h-3.5 w-5 rounded-[3px]',
    sm: 'h-4 w-6 rounded-[4px]',
    md: 'h-7 w-10 rounded-md',
    lg: 'h-11 w-16 rounded-lg',
  }[size];

  if (!isValidIso || imgError) {
    return (
      <span
        aria-hidden="true"
        className={cn(
          'inline-flex shrink-0 items-center justify-center bg-muted text-sm',
          sizeClass,
          className,
        )}
      >
        {emojiFallback ?? '🌍'}
      </span>
    );
  }

  return (
    <img
      src={`https://flagcdn.com/w80/${normalized}.png`}
      srcSet={`https://flagcdn.com/w160/${normalized}.png 2x`}
      alt={name ? `${name} flag` : `${code.toUpperCase()} flag`}
      loading="lazy"
      onError={() => setImgError(true)}
      className={cn(
        'shrink-0 border border-border object-cover',
        sizeClass,
        className,
      )}
    />
  );
}
