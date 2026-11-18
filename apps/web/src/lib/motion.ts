import type { Transition, Variants } from 'motion/react';

/**
 * Shared PekSoft motion tokens aligned with packages/design-tokens/tokens.json:
 * - instant: 0ms
 * - fast: 120ms
 * - normal: 220ms
 * - slow: 360ms
 *
 * Rules:
 * - Animate transform and opacity only (zero layout shift).
 * - Never delay audio controls or the Largest Contentful Paint element.
 */
export const MOTION_DURATIONS = {
  instant: 0,
  fast: 0.12,
  normal: 0.22,
  slow: 0.36,
} as const;

export const MOTION_EASINGS = {
  standard: [0.22, 1, 0.36, 1] as const,
  exit: [0.4, 0, 1, 1] as const,
} as const;

export const MOTION_SPRINGS = {
  snappy: {
    type: 'spring' as const,
    stiffness: 420,
    damping: 32,
    mass: 0.8,
  },
  gentle: {
    type: 'spring' as const,
    stiffness: 260,
    damping: 26,
    mass: 0.9,
  },
} as const;

export const MOTION_STAGGER = {
  fast: 0.035,
  normal: 0.055,
} as const;

export const TRANSITION_FAST: Transition = {
  duration: MOTION_DURATIONS.fast,
  ease: MOTION_EASINGS.standard,
};

export const TRANSITION_NORMAL: Transition = {
  duration: MOTION_DURATIONS.normal,
  ease: MOTION_EASINGS.standard,
};

export const TRANSITION_SLOW: Transition = {
  duration: MOTION_DURATIONS.slow,
  ease: MOTION_EASINGS.standard,
};

export const FADE_UP_VARIANTS: {
  container: Variants;
  item: Variants;
} = {
  container: {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: MOTION_STAGGER.fast,
      },
    },
  },
  item: {
    hidden: { opacity: 0, y: 12 },
    visible: {
      opacity: 1,
      y: 0,
      transition: TRANSITION_NORMAL,
    },
  },
};
