'use client';

import { motion } from 'motion/react';
import { TRANSITION_FAST } from '@/lib/motion';

export default function AppTemplate({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={TRANSITION_FAST}
    >
      {children}
    </motion.div>
  );
}
