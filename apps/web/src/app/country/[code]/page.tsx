import type { Metadata } from 'next';
import { CountryClient } from '@/app/country/[code]/country-client';
import { fetchCountryMeta, searchStations } from '@/lib/api-client';
import { buildMetadata } from '@/lib/seo';

export const revalidate = 300;

export async function generateMetadata({
  params,
}: {
  params: Promise<{ code: string }>;
}): Promise<Metadata> {
  const { code } = await params;
  const country = await fetchCountryMeta(code);
  return buildMetadata({
    title: `${country.name} Radio Stations`,
    description: `Listen to ${country.workingCount} live radio stations from ${country.name} ${country.flag} in your browser.`,
    path: `/country/${code.toLowerCase()}`,
  });
}

export default async function CountryDetailPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  const [country, initialStations] = await Promise.all([
    fetchCountryMeta(code),
    searchStations({
      country: code.toUpperCase(),
      limit: 40,
      workingOnly: true,
    }),
  ]);

  return <CountryClient country={country} initialStations={initialStations} />;
}
