'use client';

import { useState } from 'react';
import { cn } from '@/lib/utils';

const FALLBACK_IMAGES = [
  '/images/genres/afrobeats.jpg',
  '/images/genres/jazz.jpg',
  '/images/genres/electronic.jpg',
  '/images/genres/news.jpg',
  '/images/genres/classical.jpg',
  '/images/genres/gospel.jpg',
  '/images/genres/pop.jpg',
  '/images/genres/rock.jpg',
  '/images/genres/sports.jpg',
  '/images/genres/hiphop.jpg',
] as const;

const GENRE_IMAGE_MAP: Record<string, string> = {
  afrobeats: '/images/genres/afrobeats.jpg',
  bollywood: '/images/genres/bollywood.jpg',
  classical: '/images/genres/classical.jpg',
  country: '/images/genres/country.jpg',
  electronic: '/images/genres/electronic.jpg',
  gospel: '/images/genres/gospel.jpg',
  highlife: '/images/genres/highlife.jpg',
  hiphop: '/images/genres/hiphop.jpg',
  islamic: '/images/genres/islamic.jpg',
  jazz: '/images/genres/jazz.jpg',
  jpop: '/images/genres/jpop.jpg',
  latin: '/images/genres/latin.jpg',
  lounge: '/images/genres/lounge.jpg',
  news: '/images/genres/news.jpg',
  oldies: '/images/genres/oldies.jpg',
  pop: '/images/genres/pop.jpg',
  reggae: '/images/genres/reggae.jpg',
  rock: '/images/genres/rock.jpg',
  soul: '/images/genres/soul.jpg',
  sports: '/images/genres/sports.jpg',
};

const NAME_THEME_RULES: ReadonlyArray<{ pattern: RegExp; image: string }> = [
  {
    pattern:
      /\b(gospel|praise|worship|christian|church|jesus|christ|bible|faith|grace|hymn|choir)\b/i,
    image: '/images/genres/gospel.jpg',
  },
  {
    pattern:
      /\b(sport|sports|football|soccer|premier|nba|nfl|espn|brila|stadium|athletic)\b/i,
    image: '/images/genres/sports.jpg',
  },
  {
    pattern:
      /\b(news|talk|info|bbc|npr|cnn|rfi|rmc|rtl|headline|parliament|world service)\b/i,
    image: '/images/genres/news.jpg',
  },
  {
    pattern: /\b(quran|koran|islamic|islam|mosque|sunnah|ramadan)\b/i,
    image: '/images/genres/islamic.jpg',
  },
  {
    pattern: /\b(jazz|swing|bossa|sax)\b/i,
    image: '/images/genres/jazz.jpg',
  },
  {
    pattern: /\b(soul|funk|motown|r&b|rnb)\b/i,
    image: '/images/genres/soul.jpg',
  },
  {
    pattern: /\b(hiphop|hip-hop|hip hop|rap|trap|urban)\b/i,
    image: '/images/genres/hiphop.jpg',
  },
  {
    pattern: /\b(rock|metal|punk|indie|alt|alternative|grunge)\b/i,
    image: '/images/genres/rock.jpg',
  },
  {
    pattern: /\b(pop|hits|top 40|top40|chart|charts|hot)\b/i,
    image: '/images/genres/pop.jpg',
  },
  {
    pattern: /\b(reggae|dancehall|dub|ska|jamaica)\b/i,
    image: '/images/genres/reggae.jpg',
  },
  {
    pattern: /\b(latin|salsa|samba|bachata|reggaeton|cumbia|tango)\b/i,
    image: '/images/genres/latin.jpg',
  },
  {
    pattern: /\b(country|nashville|bluegrass|folk|americana)\b/i,
    image: '/images/genres/country.jpg',
  },
  {
    pattern: /\b(oldies|retro|80s|70s|60s|golden|nostalgia|vintage)\b/i,
    image: '/images/genres/oldies.jpg',
  },
  {
    pattern: /\b(lounge|chill|ambient|lofi|lo-fi|relax|zen|cafe|smooth)\b/i,
    image: '/images/genres/lounge.jpg',
  },
  {
    pattern:
      /\b(classic|classical|symphony|philharmonic|orchestra|piano|opera|baroque|mozart|bach|concert)\b/i,
    image: '/images/genres/classical.jpg',
  },
  {
    pattern: /\b(highlife|juju|fuji)\b/i,
    image: '/images/genres/highlife.jpg',
  },
  {
    pattern: /\b(afro|afrobeats|naija|lagos|abuja|ghana|accra|amapiano|wazobia)\b/i,
    image: '/images/genres/afrobeats.jpg',
  },
  {
    pattern: /\b(jpop|j-pop|anime|tokyo|shibuya)\b/i,
    image: '/images/genres/jpop.jpg',
  },
  {
    pattern: /\b(bollywood|desi|hindi|bhangra|punjabi)\b/i,
    image: '/images/genres/bollywood.jpg',
  },
  {
    pattern: /\b(electronic|dance|house|techno|trance|edm|club|synth|rave|disco)\b/i,
    image: '/images/genres/electronic.jpg',
  },
];

export function resolveFallbackArtwork(
  name: string,
  genres?: readonly string[],
  genreHint?: string,
): string {
  const allGenres = [
    ...(genres ?? []),
    ...(genreHint ? [genreHint] : []),
  ].map((g) => g.toLowerCase());

  for (const g of allGenres) {
    if (GENRE_IMAGE_MAP[g]) {
      return GENRE_IMAGE_MAP[g]!;
    }
  }

  for (const rule of NAME_THEME_RULES) {
    if (rule.pattern.test(name)) {
      return rule.image;
    }
  }

  let hash = 0;
  for (let i = 0; i < name.length; i += 1) {
    hash = (hash * 31 + name.charCodeAt(i)) | 0;
  }
  return (
    FALLBACK_IMAGES[Math.abs(hash) % FALLBACK_IMAGES.length] ??
    FALLBACK_IMAGES[0]
  );
}

export function StationArtwork({
  name,
  faviconUrl,
  genres,
  genreHint,
  size = 'md',
  className,
}: {
  name: string;
  faviconUrl: string | null;
  genres?: readonly string[];
  genreHint?: string;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}) {
  const [imgError, setImgError] = useState(false);

  const sizeClass = {
    sm: 'size-10 rounded-lg',
    md: 'size-12 rounded-xl',
    lg: 'size-16 rounded-xl',
    xl: 'size-28 rounded-2xl',
  }[size];

  const hasValidFavicon = Boolean(
    faviconUrl && faviconUrl.trim().length > 0 && !imgError,
  );
  const src = hasValidFavicon
    ? faviconUrl!.trim()
    : resolveFallbackArtwork(name, genres, genreHint);

  return (
    <img
      src={src}
      alt={`${name} artwork`}
      onError={() => {
        if (!imgError) setImgError(true);
      }}
      className={cn(
        'shrink-0 border border-border bg-muted object-cover',
        sizeClass,
        className,
      )}
    />
  );
}
