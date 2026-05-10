# [09/05/2026 - Alexandre Carvalho] frota-api — Node 22 alpine
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev --no-audit --no-fund

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3030

COPY --from=deps /app/node_modules ./node_modules
COPY package*.json ./
COPY src ./src

# Healthcheck nativo Docker — bate em /health
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget --spider -q http://127.0.0.1:${PORT}/health || exit 1

EXPOSE 3030
USER node
CMD ["node", "src/server.js"]
