import { ImageResponse } from 'next/og';
import { APP_NAME } from '@peksoft/shared';

export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default function OpenGraphImage() {
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
            'linear-gradient(135deg, #0A0F1C 0%, #101A2E 55%, #18243E 100%)',
          color: '#F8FAFC',
          fontFamily: 'sans-serif',
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '16px',
          }}
        >
          <div
            style={{
              width: '20px',
              height: '20px',
              borderRadius: '9999px',
              background: '#FFB020',
            }}
          />
          <span
            style={{
              fontSize: '28px',
              fontWeight: 700,
              color: '#FFB020',
              letterSpacing: '-0.02em',
            }}
          >
            {APP_NAME}
          </span>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div
            style={{
              fontSize: '64px',
              fontWeight: 700,
              lineHeight: 1.1,
              letterSpacing: '-0.03em',
              maxWidth: '920px',
            }}
          >
            Every radio station in the world, one tap away.
          </div>
          <div
            style={{
              fontSize: '28px',
              color: '#94A3B8',
              maxWidth: '820px',
            }}
          >
            Verified live FM &amp; internet radio by country, language, and
            genre.
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '24px',
            fontSize: '22px',
            color: '#CBD5E1',
          }}
        >
          <span>30,000+ Live Stations</span>
          <span>·</span>
          <span>Zero Setup</span>
          <span>·</span>
          <span>Android &amp; Web</span>
        </div>
      </div>
    ),
    size,
  );
}
