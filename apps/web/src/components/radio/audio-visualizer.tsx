'use client';

import { motion, useReducedMotion } from 'motion/react';
import { cn } from '@/lib/utils';

const DECORATIVE_TARGETS = [
  [0.3, 0.95, 0.45, 0.85, 0.3],
  [0.85, 0.35, 0.9, 0.4, 0.85],
  [0.45, 0.9, 0.35, 0.95, 0.45],
  [0.75, 0.4, 0.85, 0.3, 0.75],
] as const;

export function AudioVisualizer({
  isPlaying,
  corsAnalyserActive = false,
  levels,
  className,
}: {
  isPlaying: boolean;
  corsAnalyserActive?: boolean;
  levels?: readonly number[];
  className?: string;
}) {
  const reducedMotion = useReducedMotion();

  return (
    <div
      aria-hidden="true"
      className={cn('flex h-4 items-end gap-0.5', className)}
    >
      {DECORATIVE_TARGETS.map((keyframes, idx) => {
        if (corsAnalyserActive && levels && levels[idx] !== undefined) {
          return (
            <span
              key={idx}
              className="w-1 origin-bottom rounded-full bg-[var(--color-accent)] transition-transform duration-75"
              style={{
                height: '100%',
                transform: `scaleY(${isPlaying ? levels[idx] : 0.25})`,
              }}
            />
          );
        }

        if (!isPlaying || reducedMotion) {
          return (
            <span
              key={idx}
              className={cn(
                'w-1 rounded-full transition-colors',
                isPlaying ? 'bg-[var(--color-accent)]' : 'bg-muted-foreground/40',
              )}
              style={{
                height: '100%',
                transform: `scaleY(${isPlaying ? 0.65 - (idx % 2) * 0.2 : 0.25})`,
                transformOrigin: 'bottom',
              }}
            />
          );
        }

        return (
          <motion.span
            key={idx}
            className="w-1 origin-bottom rounded-full bg-[var(--color-accent)]"
            style={{ height: '100%' }}
            animate={{ scaleY: [...keyframes] }}
            transition={{
              duration: 0.9 + idx * 0.12,
              repeat: Infinity,
              ease: 'easeInOut',
            }}
          />
        );
      })}
    </div>
  );
}
