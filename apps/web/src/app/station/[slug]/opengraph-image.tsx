import { ImageResponse } from 'next/og';
import { APP_NAME } from '@peksoft/shared';
import { fetchStationBySlugOrId } from '@/lib/api-client';

export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default async function StationOpenGraphImage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const station = await fetchStationBySlugOrId(slug);
  const name = station?.name ?? 'Live Radio Station';
  const subtitle = station
    ? `${station.countryFlag} ${station.countryName} · ${station.codec}${
        station.bitrateKbps > 0 ? ` · ${station.bitrateKbps} kbps` : ''
      }`
    : 'Stream live on PekSoft Radio';

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: '64px',
          background:
            'linear-gradient(135deg, #0A0F1C 0%, #101A2E 60%, #1E293B 100%)',
          color: '#F8FAFC',
          fontFamily: 'sans-serif',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div
            style={{
              width: '18px',
              height: '18px',
              borderRadius: '9999px',
              background: '#22C55E',
            }}
          />
          <span
            style={{
              fontSize: '24px',
              fontWeight: 700,
              color: '#FFB020',
            }}
          >
            {APP_NAME} · LIVE
          </span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '18px' }}>
          <div
            style={{
              fontSize: '68px',
              fontWeight: 700,
              lineHeight: 1.08,
              letterSpacing: '-0.03em',
            }}
          >
            {name}
          </div>
          <div style={{ fontSize: '30px', color: '#CBD5E1' }}>{subtitle}</div>
        </div>

        <div style={{ fontSize: '22px', color: '#94A3B8' }}>
          Listen live in your browser or on Android
        </div>
      </div>
    ),
    size,
  );
}
