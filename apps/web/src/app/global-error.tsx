'use client';

import { useEffect } from 'react';
import { captureWebException } from '@/lib/sentry';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    void captureWebException(error, {
      route: typeof window !== 'undefined' ? window.location.pathname : undefined,
      digest: error.digest,
    });
  }, [error]);

  return (
    <html lang="en" className="dark">
      <body className="flex min-h-screen items-center justify-center bg-[#0B0E17] p-6 text-white">
        <div className="w-full max-w-md rounded-xl border border-[#262B3D] bg-[#131826] p-6 text-center">
          <h1 className="text-xl font-bold">Something went wrong</h1>
          <p className="mt-2 text-sm text-[#94A3B8]">
            An unexpected error occurred. The issue has been reported without
            personal data.
          </p>
          <button
            type="button"
            onClick={reset}
            className="mt-5 inline-flex h-11 items-center justify-center rounded-lg bg-[#8A2BE2] px-5 text-sm font-semibold text-white hover:bg-[#7A22CC]"
          >
            Try again
          </button>
        </div>
      </body>
    </html>
  );
}
