import type { MetadataRoute } from 'next';
import { APP_NAME } from '@peksoft/shared';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: APP_NAME,
    short_name: 'PekSoft Radio',
    description: 'Every radio station in the world, one tap away.',
    start_url: '/home',
    display: 'standalone',
    background_color: '#0A0F1C',
    theme_color: '#0A0F1C',
    icons: [
      {
        src: '/icon.png',
        sizes: '512x512',
        type: 'image/png',
      },
      {
        src: '/apple-icon.png',
        sizes: '180x180',
        type: 'image/png',
      },
    ],
  };
}
