import { ExploreClient } from '@/app/explore/explore-client';
import {
  fetchCountries,
  fetchGenres,
  fetchLanguages,
  searchStations,
} from '@/lib/api-client';
import { buildMetadata } from '@/lib/seo';

export const revalidate = 120;

export const metadata = buildMetadata({
  title: 'Explore Global Radio Stations',
  description:
    'Browse verified live radio stations by country, canonical genre, broadcast language, and HTTPS browser playability.',
  path: '/explore',
});

export default async function ExplorePage() {
  const [initialStations, countries, genres, languages] = await Promise.all([
    searchStations({ limit: 40, workingOnly: true, sort: 'popular' }),
    fetchCountries(),
    fetchGenres(),
    fetchLanguages(),
  ]);

  return (
    <ExploreClient
      initialStations={initialStations}
      countries={countries}
      genres={genres}
      languages={languages}
    />
  );
}
