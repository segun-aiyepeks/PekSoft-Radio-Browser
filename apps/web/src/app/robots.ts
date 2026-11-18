import type { MetadataRoute } from 'next';
import { getSiteUrl } from '@/lib/seo';

export default function robots(): MetadataRoute.Robots {
  const siteUrl = getSiteUrl();
  return {
    rules: [
      {
        userAgent: '*',
        allow: ['/', '/home', '/explore', '/country/', '/genre/', '/station/', '/pricing'],
        disallow: ['/api/', '/account', '/library', '/auth', '/dev/'],
      },
    ],
    sitemap: `${siteUrl}/sitemap.xml`,
  };
}
