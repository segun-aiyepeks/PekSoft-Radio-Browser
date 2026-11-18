import type { MetadataRoute } from 'next';
import {
  fetchCountries,
  fetchGenres,
  fetchTrendingStations,
} from '@/lib/api-client';
import { getSiteUrl } from '@/lib/seo';

export const revalidate = 3600;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const siteUrl = getSiteUrl();
  const now = new Date();

  const [countries, genres, stations] = await Promise.all([
    fetchCountries(),
    fetchGenres(),
    fetchTrendingStations({ limit: 40 }),
  ]);

  const staticRoutes: MetadataRoute.Sitemap = [
    { url: `${siteUrl}/`, lastModified: now, changeFrequency: 'daily', priority: 1.0 },
    { url: `${siteUrl}/home`, lastModified: now, changeFrequency: 'hourly', priority: 0.9 },
    { url: `${siteUrl}/explore`, lastModified: now, changeFrequency: 'hourly', priority: 0.9 },
    { url: `${siteUrl}/pricing`, lastModified: now, changeFrequency: 'weekly', priority: 0.6 },
  ];

  const countryRoutes: MetadataRoute.Sitemap = countries.slice(0, 50).map((c) => ({
    url: `${siteUrl}/country/${c.code.toLowerCase()}`,
    lastModified: now,
    changeFrequency: 'daily',
    priority: 0.7,
  }));

  const genreRoutes: MetadataRoute.Sitemap = genres.map((g) => ({
    url: `${siteUrl}/genre/${g.slug}`,
    lastModified: now,
    changeFrequency: 'daily',
    priority: 0.7,
  }));

  const stationRoutes: MetadataRoute.Sitemap = stations.map((s) => ({
    url: `${siteUrl}/station/${s.slug}`,
    lastModified: now,
    changeFrequency: 'daily',
    priority: 0.8,
  }));

  return [...staticRoutes, ...countryRoutes, ...genreRoutes, ...stationRoutes];
}
