# syntax=docker/dockerfile:1

FROM node:22-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssl ca-certificates wget \
  && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@12.18.0 --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml tsconfig.base.json ./
COPY packages/shared packages/shared
COPY packages/design-tokens/package.json packages/design-tokens/package.json
COPY apps/web/package.json apps/web/package.json
COPY apps/api apps/api

RUN pnpm install --frozen-lockfile --prod=false
RUN pnpm --filter @peksoft/shared build
RUN pnpm --filter @peksoft/api exec prisma generate
RUN pnpm --filter @peksoft/api build

ENV NODE_ENV=production
WORKDIR /app/apps/api
EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:4000/health || exit 1

CMD ["sh", "-c", "set -e; if [ -n \"$DATABASE_URL\" ]; then pnpm exec prisma migrate resolve --rolled-back 0001_init || true; pnpm exec prisma migrate deploy; fi; exec node dist/index.js"]
