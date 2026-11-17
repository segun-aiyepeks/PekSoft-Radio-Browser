import { HomeClient } from '@/app/home/home-client';
import { fetchGenres, fetchTrendingStations } from '@/lib/api-client';
import { buildMetadata } from '@/lib/seo';

export const revalidate = 120;

export const metadata = buildMetadata({
  title: 'Home — Live Radio & Curated Collections',
  description:
    'Listen to trending verified stations, local picks from Nigeria, and curated genre collections.',
  path: '/home',
});

export default async function HomePage() {
  const [trendingStations, nigeriaStations, genres] = await Promise.all([
    fetchTrendingStations({ limit: 12 }),
    fetchTrendingStations({ limit: 6, country: 'NG' }),
    fetchGenres(),
  ]);

  return (
    <HomeClient
      trendingStations={trendingStations}
      nigeriaStations={nigeriaStations}
      genres={genres}
    />
  );
}
