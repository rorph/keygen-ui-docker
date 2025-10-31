# Keygen UI Dockerfile
# Multi-stage build for Next.js 15 application with pnpm

# Stage 1: Dependencies
FROM node:18-alpine AS deps
RUN coreutils --version || apk add --no-cache libc6-compat coreutils

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy package files from keygen-ui subdirectory
COPY keygen-ui/package.json keygen-ui/pnpm-lock.yaml* keygen-ui/pnpm-workspace.yaml* ./

# Install dependencies with frozen lockfile
RUN pnpm install --frozen-lockfile

# Stage 2: Builder
FROM node:18-alpine AS builder

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy application source from keygen-ui subdirectory
COPY keygen-ui/ ./

# Accept build arguments for Next.js public environment variables
ARG NEXT_PUBLIC_KEYGEN_API_URL=https://api.keygen.sh/v1
ARG NEXT_PUBLIC_KEYGEN_ACCOUNT_ID

# Set environment variables for build
# Next.js will use these during build time
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NEXT_PUBLIC_KEYGEN_API_URL=${NEXT_PUBLIC_KEYGEN_API_URL}
ENV NEXT_PUBLIC_KEYGEN_ACCOUNT_ID=${NEXT_PUBLIC_KEYGEN_ACCOUNT_ID}

# Build the application with Turbopack
RUN pnpm build

# Stage 3: Runner
FROM node:18-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV COREPACK_ENABLE_AUTO_PIN=0

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Install pnpm globally with corepack (non-interactive)
RUN corepack enable && corepack prepare pnpm@latest --activate

# Copy everything needed from builder with correct ownership
COPY --from=builder --chown=nextjs:nodejs /app/package.json /app/pnpm-lock.yaml* ./
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/next.config.ts ./

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3000

ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Start the application using Next.js start command via pnpm
CMD ["pnpm", "start"]
