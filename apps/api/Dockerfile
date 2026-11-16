# syntax=docker/dockerfile:1

FROM node:22-alpine AS base
RUN corepack enable && corepack prepare pnpm@12.18.0 --activate
WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/shared/package.json packages/shared/package.json
COPY packages/design-tokens/package.json packages/design-tokens/package.json
COPY apps/api/package.json apps/api/package.json
COPY apps/web/package.json apps/web/package.json
RUN pnpm install --frozen-lockfile

FROM deps AS build
COPY tsconfig.base.json ./
COPY packages/shared packages/shared
COPY apps/api apps/api
RUN pnpm --filter @peksoft/shared build && pnpm --filter @peksoft/api db:generate && pnpm --filter @peksoft/api build
RUN pnpm --filter @peksoft/api --prod deploy /prod/api
COPY apps/api/prisma /prod/api/prisma
COPY apps/api/prisma.config.ts /prod/api/prisma.config.ts
RUN cd /prod/api && ./node_modules/.bin/prisma generate

FROM node:22-alpine AS runner
ENV NODE_ENV=production
WORKDIR /app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=build --chown=appuser:appgroup /prod/api ./
USER appuser
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1:4000/health || exit 1
CMD ["sh", "-c", "set -e; if [ -n \"$DATABASE_URL\" ]; then ./node_modules/.bin/prisma migrate deploy; fi; exec node dist/index.js"]
