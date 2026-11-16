import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';

export interface DatabaseHandle {
  prisma: PrismaClient;
  close(): Promise<void>;
}

export function createPrismaClient(databaseUrl: string): DatabaseHandle {
  const pool = new Pool({ connectionString: databaseUrl });
  const adapter = new PrismaPg(pool);
  const prisma = new PrismaClient({ adapter });

  return {
    prisma,
    async close() {
      await prisma.$disconnect();
      await pool.end();
    },
  };
}
