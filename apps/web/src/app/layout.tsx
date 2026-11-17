import type { Metadata } from 'next';
import { Inter, Space_Grotesk } from 'next/font/google';
import { APP_NAME } from '@peksoft/shared';
import { AppProviders } from '@/components/providers';
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
  title: APP_NAME,
  description: 'Every radio station in the world, one tap away.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html
      lang="en"
      data-theme="dark"
      className={`dark ${spaceGrotesk.variable} ${inter.variable}`}
    >
      <body className="min-h-screen bg-background text-foreground font-sans antialiased">
        <AppProviders>{children}</AppProviders>
      </body>
    </html>
  );
}
