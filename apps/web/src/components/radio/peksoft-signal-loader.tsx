'use client';

import { motion, useReducedMotion } from 'motion/react';
import { cn } from '@/lib/utils';

/**
 * Custom PekSoft Radio Browser loading indicator:
 * Displays the brand logo centered on screen while animating the three yellow
 * signal elements in sequence:
 *   1) Small dot appears first -> 2) Inner arc -> 3) Outer (largest) arc
 *   4) Outer arc disappears first -> 5) Inner arc -> 6) Small dot
 */
export function PekSoftSignalLoader({
  label = 'Tuning in…',
  size = 76,
  className,
}: {
  label?: string;
  size?: number;
  className?: string;
}) {
  const reducedMotion = useReducedMotion();

  const loopTransition = (times: number[]) => ({
    duration: 1.5,
    repeat: Infinity,
    ease: 'easeInOut' as const,
    times,
  });

  return (
    <div
      role="status"
      aria-live="polite"
      aria-label={label}
      className={cn(
        'flex flex-col items-center justify-center gap-3 select-none',
        className,
      )}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 512 512"
        width={size}
        height={size}
        fill="none"
        className="rounded-2xl border border-border shadow-lg"
      >
        <rect width="512" height="512" rx="112" fill="#101A2E" />
        <g transform="translate(8 0)">
          <rect x="152" y="136" width="48" height="240" rx="24" fill="#F4F6FB" />
          <path
            fillRule="evenodd"
            clipRule="evenodd"
            d="M176 136H228C269.974 136 304 170.026 304 212C304 253.974 269.974 288 228 288H176V136ZM200 182V242H228C244.569 242 258 228.569 258 212C258 195.431 244.569 182 228 182H200Z"
            fill="#F4F6FB"
          />

          {/* 1. Smallest signal (dot): appears 1st, disappears last */}
          <motion.circle
            cx="228"
            cy="212"
            r="15"
            fill="#FFB020"
            animate={
              reducedMotion
                ? { opacity: 1 }
                : { opacity: [0.15, 1, 1, 1, 0.15] }
            }
            transition={
              reducedMotion
                ? undefined
                : loopTransition([0, 0.15, 0.5, 0.84, 0.95])
            }
          />

          {/* 2. Medium signal (inner arc): appears 2nd, disappears 2nd */}
          <motion.path
            d="M300.2 137.2A104 104 0 0 1 300.2 286.8"
            stroke="#FFB020"
            strokeWidth="24"
            strokeLinecap="round"
            animate={
              reducedMotion
                ? { opacity: 1 }
                : { opacity: [0.15, 0.15, 1, 1, 0.15, 0.15] }
            }
            transition={
              reducedMotion
                ? undefined
                : loopTransition([0, 0.18, 0.32, 0.68, 0.8, 1])
            }
          />

          {/* 3. Largest signal (outer arc): appears 3rd, disappears 1st */}
          <motion.path
            d="M331.6 112A144 144 0 0 1 331.6 312"
            stroke="#FFB020"
            strokeWidth="24"
            strokeLinecap="round"
            animate={
              reducedMotion
                ? { opacity: 1 }
                : { opacity: [0.15, 0.15, 1, 0.15, 0.15] }
            }
            transition={
              reducedMotion
                ? undefined
                : loopTransition([0, 0.35, 0.48, 0.64, 1])
            }
          />
        </g>
      </svg>
      <span className="text-xs font-medium text-muted-foreground">{label}</span>
    </div>
  );
}
