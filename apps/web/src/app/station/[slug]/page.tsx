import type { Metadata } from 'next';
import { StationDetailClient } from '@/app/station/[slug]/station-detail-client';
import {
  fetchStationBySlugOrId,
  fetchTrendingStations,
} from '@/lib/api-client';
import { MOCK_STATIONS } from '@/lib/mock-data';
import { buildMetadata, buildStationJsonLd } from '@/lib/seo';

export const revalidate = 300;

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const station = (await fetchStationBySlugOrId(slug)) ?? MOCK_STATIONS[0]!;
  return buildMetadata({
    title: `${station.name} — Live Radio`,
    description: `Listen to ${station.name} (${station.countryName}, ${station.language}, ${station.codec}) live on PekSoft Radio.`,
    path: `/station/${slug}`,
    imagePath: `/station/${slug}/opengraph-image`,
  });
}

export default async function StationDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const [stationRaw, trending] = await Promise.all([
    fetchStationBySlugOrId(slug),
    fetchTrendingStations({ limit: 6 }),
  ]);

  const station = stationRaw ?? MOCK_STATIONS[0]!;
  const similar = trending
    .filter((s) => s.id !== station.id)
    .slice(0, 3);

  const stationJsonLd = buildStationJsonLd(station);

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(stationJsonLd) }}
      />
      <StationDetailClient station={station} similar={similar} />
    </>
  );
}
