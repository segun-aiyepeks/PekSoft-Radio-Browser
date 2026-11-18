'use client';

import dynamic from 'next/dynamic';

export const LazyInfiniteSlider = dynamic(
  () =>
    import('@/components/motion-primitives/infinite-slider').then(
      (mod) => mod.InfiniteSlider,
    ),
  { ssr: false },
);

export const LazyTilt = dynamic(
  () =>
    import('@/components/motion-primitives/tilt').then((mod) => mod.Tilt),
  {
    ssr: false,
    loading: () => null,
  },
);

export const LazySpotlight = dynamic(
  () =>
    import('@/components/motion-primitives/spotlight').then(
      (mod) => mod.Spotlight,
    ),
  { ssr: false },
);

export const LazyBorderTrail = dynamic(
  () =>
    import('@/components/motion-primitives/border-trail').then(
      (mod) => mod.BorderTrail,
    ),
  { ssr: false },
);
