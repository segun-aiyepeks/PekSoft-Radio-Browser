import type { Metadata } from 'next';
import { APP_NAME } from '@peksoft/shared';
import type { WebStation } from '@/lib/mock-data';

export function getSiteUrl(): string {
  return (
    process.env.NEXT_PUBLIC_SITE_URL || 'https://peksoftradio.com'
  ).replace(/\/+$/, '');
}

export function buildMetadata({
  title,
  description,
  path,
  imagePath = '/opengraph-image',
}: {
  title: string;
  description: string;
  path: string;
  imagePath?: string;
}): Metadata {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return {
    title,
    description,
    alternates: {
      canonical: normalizedPath,
    },
    openGraph: {
      title: `${title} | ${APP_NAME}`,
      description,
      url: normalizedPath,
      siteName: APP_NAME,
      type: 'website',
      images: [
        {
          url: imagePath,
          width: 1200,
          height: 630,
          alt: title,
        },
      ],
    },
    twitter: {
      card: 'summary_large_image',
      title: `${title} | ${APP_NAME}`,
      description,
      images: [imagePath],
    },
  };
}

export function buildWebsiteJsonLd() {
  const siteUrl = getSiteUrl();
  return {
    '@context': 'https://schema.org',
    '@type': 'WebSite',
    name: APP_NAME,
    url: siteUrl,
    description:
      'Every radio station in the world, one tap away. Live verified FM and internet radio by country, language, and genre.',
    potentialAction: {
      '@type': 'SearchAction',
      target: `${siteUrl}/explore?q={search_term_string}`,
      'query-input': 'required name=search_term_string',
    },
  };
}

export function buildStationJsonLd(station: WebStation) {
  const siteUrl = getSiteUrl();
  return {
    '@context': 'https://schema.org',
    '@type': 'RadioStation',
    name: station.name,
    url: `${siteUrl}/station/${station.slug}`,
    sameAs: station.homepage || undefined,
    areaServed: station.countryName,
    inLanguage: station.language,
    genre: station.genres,
  };
}
