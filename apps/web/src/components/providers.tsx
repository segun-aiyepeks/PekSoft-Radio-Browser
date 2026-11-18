'use client';

import { MotionConfig } from 'motion/react';
import { AdConsentProvider } from '@/components/ads/ad-consent-provider';
import { AuthProvider } from '@/components/auth/auth-provider';
import { MockSessionProvider } from '@/components/mock-session-provider';
import { Toaster } from '@/components/ui/sonner';
import { TooltipProvider } from '@/components/ui/tooltip';

export function AppProviders({ children }: { children: React.ReactNode }) {
  return (
    <MotionConfig reducedMotion="user">
      <TooltipProvider>
        <AuthProvider>
          <AdConsentProvider>
            <MockSessionProvider>{children}</MockSessionProvider>
          </AdConsentProvider>
        </AuthProvider>
        <Toaster position="bottom-right" />
      </TooltipProvider>
    </MotionConfig>
  );
}
