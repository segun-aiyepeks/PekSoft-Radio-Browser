import type { Prisma, PrismaClient } from '@prisma/client';

export interface WebhookEventRecord {
  id: string;
  provider: string;
  eventId: string;
  eventType: string;
  payload: unknown;
  processedAt: Date | null;
  createdAt: Date;
}

export interface WebhookEventRepository {
  findByProviderEventId(
    provider: string,
    eventId: string,
  ): Promise<WebhookEventRecord | null>;
  recordEvent(input: {
    provider: string;
    eventId: string;
    eventType: string;
    payload: unknown;
  }): Promise<{ record: WebhookEventRecord; isDuplicate: boolean }>;
  markProcessed(provider: string, eventId: string, at?: Date): Promise<void>;
}

export class PrismaWebhookEventRepository implements WebhookEventRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async findByProviderEventId(
    provider: string,
    eventId: string,
  ): Promise<WebhookEventRecord | null> {
    return this.prisma.webhookEvent.findUnique({
      where: {
        provider_eventId: { provider, eventId },
      },
    });
  }

  async recordEvent(input: {
    provider: string;
    eventId: string;
    eventType: string;
    payload: unknown;
  }): Promise<{ record: WebhookEventRecord; isDuplicate: boolean }> {
    const existing = await this.findByProviderEventId(
      input.provider,
      input.eventId,
    );
    if (existing) {
      return { record: existing, isDuplicate: existing.processedAt !== null };
    }

    try {
      const created = await this.prisma.webhookEvent.create({
        data: {
          provider: input.provider,
          eventId: input.eventId,
          eventType: input.eventType,
          payload: input.payload as Prisma.InputJsonValue,
        },
      });
      return { record: created, isDuplicate: false };
    } catch {
      const raced = await this.findByProviderEventId(
        input.provider,
        input.eventId,
      );
      if (raced) {
        return { record: raced, isDuplicate: raced.processedAt !== null };
      }
      throw new Error('Failed to persist webhook event');
    }
  }

  async markProcessed(
    provider: string,
    eventId: string,
    at: Date = new Date(),
  ): Promise<void> {
    await this.prisma.webhookEvent.update({
      where: {
        provider_eventId: { provider, eventId },
      },
      data: {
        processedAt: at,
      },
    });
  }
}
