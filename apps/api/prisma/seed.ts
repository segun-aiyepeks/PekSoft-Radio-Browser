import { createPrismaClient } from '../src/db/prisma.js';

async function main() {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL is required to run prisma/seed.ts');
  }

  const db = createPrismaClient(databaseUrl);

  try {
    const demoUser = await db.prisma.user.upsert({
      where: { firebaseUid: 'seed-demo-user-001' },
      update: {},
      create: {
        firebaseUid: 'seed-demo-user-001',
        email: 'listener@peksoft.radio',
        displayName: 'Demo Listener',
        entitlement: {
          create: {
            tier: 'FREE',
            status: 'ACTIVE',
            source: 'NONE',
          },
        },
        favorites: {
          create: [
            {
              stationId: '96202334-0601-11e8-ae97-52543be04c81',
              stationName: 'FIP',
              streamUrl: 'https://icecast.radiofrance.fr/fip-midfi.mp3',
              countryCode: 'FR',
              codec: 'MP3',
              bitrateKbps: 128,
            },
          ],
        },
        collections: {
          create: [
            {
              name: 'Morning Focus',
              description: 'Calm instrumental and jazz stations',
              items: {
                create: [
                  {
                    stationId: '96202334-0601-11e8-ae97-52543be04c81',
                    stationName: 'FIP',
                    streamUrl: 'https://icecast.radiofrance.fr/fip-midfi.mp3',
                    countryCode: 'FR',
                    position: 0,
                  },
                ],
              },
            },
          ],
        },
      },
    });

    console.log(`Seeded demo user ${demoUser.id} (${demoUser.firebaseUid})`);
  } finally {
    await db.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
