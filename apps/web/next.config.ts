import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@peksoft/shared', '@peksoft/design-tokens'],
};

export default nextConfig;
