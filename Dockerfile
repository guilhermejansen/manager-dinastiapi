# ==============================================================================
# Multi-Stage Dockerfile for Next.js 16 with Prisma
# Optimized for production deployment without source code exposure
# Supports: linux/amd64, linux/arm64
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Builder
# Build the application with all dependencies
# ------------------------------------------------------------------------------
FROM node:20-alpine AS builder

# Reuse resilient npm settings during the full build
ENV NPM_CONFIG_FETCH_RETRIES=5 \
    NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=20000 \
    NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT=120000 \
    NPM_CONFIG_REGISTRY=https://registry.npmjs.org/

# Prisma environment variables for multi-arch builds
ENV PRISMA_CLI_BINARY_TARGETS=native

# Install build dependencies
RUN apk add --no-cache libc6-compat python3 make g++ openssl

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Copy Prisma schema and migrations first (needed for postinstall)
COPY prisma ./prisma/

# Install all dependencies (Prisma Client will be generated via postinstall)
RUN npm ci && \
    npm cache clean --force

# Copy source code
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

RUN npm run build

# Build worker bundle (postbuild runs automatically, but ensure artifacts exist)
RUN test -d dist/workers

# Prune devDependencies to reduce final image size
RUN npm prune --omit=dev

# ------------------------------------------------------------------------------
# Stage 2: Runner
# Final production image with minimal footprint
# ------------------------------------------------------------------------------
FROM node:20-alpine AS runner

# Install runtime dependencies
RUN apk add --no-cache \
    libc6-compat \
    ca-certificates \
    tzdata \
    curl \
    netcat-openbsd \
    && rm -rf /var/cache/apk/*

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Set timezone (can be overridden via environment variable)
ENV TZ=America/Sao_Paulo

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nodejs

# Copy production node_modules from builder stage
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy Prisma files (needed for migrations at runtime)
COPY --from=builder --chown=nodejs:nodejs /app/prisma ./prisma

# Copy Next.js standalone build output
# This includes the compiled server and minimal dependencies
COPY --from=builder --chown=nodejs:nodejs /app/.next/standalone ./

# Copy static files
COPY --from=builder --chown=nodejs:nodejs /app/.next/static ./.next/static

# Copy public folder
COPY --from=builder --chown=nodejs:nodejs /app/public ./public

# Copy compiled worker bundle
COPY --from=builder --chown=nodejs:nodejs /app/dist/workers ./dist/workers

# Remove TypeScript build info artifacts
RUN rm -f dist/workers/tsconfig.workers.tsbuildinfo

# Copy package.json for metadata
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./package.json

# Copy entrypoint script
COPY --chown=nodejs:nodejs docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy healthcheck script
COPY --chown=nodejs:nodejs healthcheck.js ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Set hostname
ENV HOSTNAME="0.0.0.0"
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node healthcheck.js || exit 1

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command (can be overridden for workers)
CMD ["node", "server.js"]
