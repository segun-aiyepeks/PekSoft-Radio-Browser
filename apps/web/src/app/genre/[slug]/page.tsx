import type { Metadata } from 'next';
import { GenreClient } from '@/app/genre/[slug]/genre-client';
import { fetchGenreMeta, searchStations } from '@/lib/api-client';
import { buildMetadata } from '@/lib/seo';

export const revalidate = 300;

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const genre = await fetchGenreMeta(slug);
  return buildMetadata({
    title: `${genre.name} Radio Stations`,
    description: `${genre.tagline}. Stream live ${genre.name} stations on PekSoft Radio.`,
    path: `/genre/${genre.slug}`,
  });
}

export default async function GenreDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const [genre, initialStations] = await Promise.all([
    fetchGenreMeta(slug),
    searchStations({ genre: slug, limit: 40, workingOnly: true }),
  ]);

  return <GenreClient genre={genre} initialStations={initialStations} />;
}
