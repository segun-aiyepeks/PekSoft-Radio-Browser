import type { Metadata } from 'next';
import { Inter, Space_Grotesk } from 'next/font/google';
import { APP_NAME } from '@peksoft/shared';
import { AppProviders } from '@/components/providers';
import { buildWebsiteJsonLd, getSiteUrl } from '@/lib/seo';
import './globals.css';

const spaceGrotesk = Space_Grotesk({
  subsets: ['latin'],
  weight: ['500', '600', '700'],
  variable: '--font-space-grotesk',
  display: 'swap',
});

const inter = Inter({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-inter',
  display: 'swap',
});

export const metadata: Metadata = {
  metadataBase: new URL(getSiteUrl()),
  title: {
    default: APP_NAME,
    template: `%s | ${APP_NAME}`,
  },
  description: 'Every radio station in the world, one tap away.',
  alternates: {
    canonical: '/',
  },
  openGraph: {
    type: 'website',
    siteName: APP_NAME,
    title: APP_NAME,
    description: 'Every radio station in the world, one tap away.',
    images: [{ url: '/opengraph-image', width: 1200, height: 630, alt: APP_NAME }],
  },
  twitter: {
    card: 'summary_large_image',
    title: APP_NAME,
    description: 'Every radio station in the world, one tap away.',
    images: ['/opengraph-image'],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const websiteJsonLd = buildWebsiteJsonLd();
  return (
    <html
      lang="en"
      data-theme="dark"
      className={`dark ${spaceGrotesk.variable} ${inter.variable}`}
    >
      <body className="min-h-screen bg-background text-foreground font-sans antialiased">
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(websiteJsonLd) }}
        />
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  );
}
