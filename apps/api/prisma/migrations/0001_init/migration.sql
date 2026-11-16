-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "EntitlementTier" AS ENUM ('FREE', 'PLUS');

-- CreateEnum
CREATE TYPE "EntitlementStatus" AS ENUM ('ACTIVE', 'GRACE', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "EntitlementSource" AS ENUM ('NONE', 'GOOGLE_PLAY', 'PAYSTACK', 'PROMO');

-- CreateEnum
CREATE TYPE "ReportReason" AS ENUM ('DEAD_STREAM', 'WRONG_INFO', 'OFFENSIVE', 'OTHER');

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('OPEN', 'REVIEWED', 'RESOLVED');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "firebase_uid" TEXT NOT NULL,
    "email" TEXT,
    "display_name" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "favorites" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "station_id" TEXT NOT NULL,
    "station_name" TEXT NOT NULL,
    "stream_url" TEXT NOT NULL,
    "country_code" TEXT NOT NULL DEFAULT '',
    "favicon_url" TEXT,
    "codec" TEXT,
    "bitrate_kbps" INTEGER,
    "is_deleted" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "favorites_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "collections" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "is_deleted" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "collections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "collection_items" (
    "id" UUID NOT NULL,
    "collection_id" UUID NOT NULL,
    "station_id" TEXT NOT NULL,
    "station_name" TEXT NOT NULL,
    "stream_url" TEXT NOT NULL,
    "country_code" TEXT NOT NULL DEFAULT '',
    "position" INTEGER NOT NULL DEFAULT 0,
    "is_deleted" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "collection_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recents" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "station_id" TEXT NOT NULL,
    "station_name" TEXT NOT NULL,
    "stream_url" TEXT NOT NULL,
    "country_code" TEXT NOT NULL DEFAULT '',
    "played_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "recents_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "song_history" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "station_id" TEXT NOT NULL,
    "station_name" TEXT NOT NULL,
    "track_title" TEXT NOT NULL,
    "heard_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "song_history_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "entitlements" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "tier" "EntitlementTier" NOT NULL DEFAULT 'FREE',
    "status" "EntitlementStatus" NOT NULL DEFAULT 'ACTIVE',
    "source" "EntitlementSource" NOT NULL DEFAULT 'NONE',
    "external_customer_id" TEXT,
    "external_subscription_id" TEXT,
    "expires_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "entitlements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "webhook_events" (
    "id" UUID NOT NULL,
    "provider" TEXT NOT NULL,
    "event_id" TEXT NOT NULL,
    "event_type" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "processed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "webhook_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "station_reports" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "station_id" TEXT NOT NULL,
    "station_name" TEXT NOT NULL,
    "reason" "ReportReason" NOT NULL,
    "notes" TEXT,
    "status" "ReportStatus" NOT NULL DEFAULT 'OPEN',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "station_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_firebase_uid_key" ON "users"("firebase_uid");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "favorites_user_id_updated_at_idx" ON "favorites"("user_id", "updated_at");

-- CreateIndex
CREATE UNIQUE INDEX "favorites_user_id_station_id_key" ON "favorites"("user_id", "station_id");

-- CreateIndex
CREATE INDEX "collections_user_id_updated_at_idx" ON "collections"("user_id", "updated_at");

-- CreateIndex
CREATE INDEX "collection_items_collection_id_position_idx" ON "collection_items"("collection_id", "position");

-- CreateIndex
CREATE INDEX "collection_items_collection_id_updated_at_idx" ON "collection_items"("collection_id", "updated_at");

-- CreateIndex
CREATE UNIQUE INDEX "collection_items_collection_id_station_id_key" ON "collection_items"("collection_id", "station_id");

-- CreateIndex
CREATE INDEX "recents_user_id_played_at_idx" ON "recents"("user_id", "played_at" DESC);

-- CreateIndex
CREATE INDEX "recents_user_id_updated_at_idx" ON "recents"("user_id", "updated_at");

-- CreateIndex
CREATE UNIQUE INDEX "recents_user_id_station_id_key" ON "recents"("user_id", "station_id");

-- CreateIndex
CREATE INDEX "song_history_user_id_heard_at_idx" ON "song_history"("user_id", "heard_at" DESC);

-- CreateIndex
CREATE INDEX "song_history_user_id_updated_at_idx" ON "song_history"("user_id", "updated_at");

-- CreateIndex
CREATE UNIQUE INDEX "entitlements_user_id_key" ON "entitlements"("user_id");

-- CreateIndex
CREATE INDEX "entitlements_status_expires_at_idx" ON "entitlements"("status", "expires_at");

-- CreateIndex
CREATE INDEX "webhook_events_provider_created_at_idx" ON "webhook_events"("provider", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "webhook_events_provider_event_id_key" ON "webhook_events"("provider", "event_id");

-- CreateIndex
CREATE INDEX "station_reports_station_id_status_idx" ON "station_reports"("station_id", "status");

-- CreateIndex
CREATE INDEX "station_reports_created_at_idx" ON "station_reports"("created_at");

-- AddForeignKey
ALTER TABLE "favorites" ADD CONSTRAINT "favorites_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collections" ADD CONSTRAINT "collections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "collection_items" ADD CONSTRAINT "collection_items_collection_id_fkey" FOREIGN KEY ("collection_id") REFERENCES "collections"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recents" ADD CONSTRAINT "recents_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "song_history" ADD CONSTRAINT "song_history_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "entitlements" ADD CONSTRAINT "entitlements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "station_reports" ADD CONSTRAINT "station_reports_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

