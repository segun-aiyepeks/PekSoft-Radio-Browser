import type { Metadata } from 'next';
import { APP_NAME } from '@peksoft/shared';
import './globals.css';

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
    <html lang="en">
      <body className="min-h-screen antialiased">{children}</body>
    </html>
  );
}
