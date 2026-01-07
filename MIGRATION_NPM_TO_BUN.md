# Guia Completo: Migração de NPM para Bun

> **Projeto de Referência**: manager-dinastiapi (Next.js 16 + Prisma + BullMQ + Docker)
> **Data**: Janeiro 2026
> **Resultado**: Migração 100% funcional com 0 vulnerabilidades

---

## Índice

1. [Visão Geral](#1-visão-geral)
2. [Pré-requisitos](#2-pré-requisitos)
3. [Fase 1: Preparação e Atualização de Dependências](#3-fase-1-preparação-e-atualização-de-dependências)
4. [Fase 2: Migração de Bibliotecas Problemáticas](#4-fase-2-migração-de-bibliotecas-problemáticas)
5. [Fase 3: Instalação do Bun e Migração](#5-fase-3-instalação-do-bun-e-migração)
6. [Fase 4: Configuração do Bun](#6-fase-4-configuração-do-bun)
7. [Fase 5: Atualização do package.json](#7-fase-5-atualização-do-packagejson)
8. [Fase 6: Atualização do Docker](#8-fase-6-atualização-do-docker)
9. [Fase 7: Atualização do CI/CD](#9-fase-7-atualização-do-cicd)
10. [Fase 8: Limpeza de Arquivos Obsoletos](#10-fase-8-limpeza-de-arquivos-obsoletos)
11. [Fase 9: Correções de Compatibilidade](#11-fase-9-correções-de-compatibilidade)
12. [Fase 10: Testes e Validação](#12-fase-10-testes-e-validação)
13. [Commits Recomendados](#13-commits-recomendados)
14. [Troubleshooting](#14-troubleshooting)
15. [Referência de Arquivos](#15-referência-de-arquivos)

---

## 1. Visão Geral

### O que foi migrado

| Componente | Antes | Depois |
|------------|-------|--------|
| Package Manager | npm | bun |
| Runtime | Node.js | Bun |
| Lockfile | package-lock.json | bun.lock |
| TypeScript Runner | tsx | Bun (nativo) |
| Env Loading | dotenv | Bun (nativo) |
| Docker Base | node:20-alpine | oven/bun:1.3-alpine |
| Healthcheck | healthcheck.js | healthcheck.ts |
| Workers Build | Compilado (dist/) | Source direto (lib/) |

### Benefícios Obtidos

- **Performance**: Bun é 3-4x mais rápido que npm para instalação
- **Simplicidade**: Bun executa TypeScript nativamente (sem tsx)
- **Env nativo**: Bun carrega .env automaticamente (sem dotenv)
- **Segurança**: 0 vulnerabilidades após atualização
- **Bundle menor**: Menos dependências de desenvolvimento

---

## 2. Pré-requisitos

### Instalar Bun globalmente

```bash
# macOS/Linux
curl -fsSL https://bun.sh/install | bash

# Windows (PowerShell)
powershell -c "irm bun.sh/install.ps1 | iex"

# Via npm (alternativa)
npm install -g bun
```

### Verificar instalação

```bash
bun --version
# Esperado: 1.3.x ou superior
```

### Stack suportada neste guia

- Next.js 16+
- React 19+
- Prisma 6+
- BullMQ 5+
- ioredis 5.8+
- Docker multi-stage
- GitHub Actions

---

## 3. Fase 1: Preparação e Atualização de Dependências

### 3.1 Verificar dependências desatualizadas

```bash
npm outdated
```

### 3.2 Verificar vulnerabilidades

```bash
npm audit
```

### 3.3 Atualizar todas as dependências (exceto Prisma)

```bash
# Atualizar dependências de produção
npm update

# Atualizar dependências de desenvolvimento
npm update --save-dev

# Forçar atualização para últimas versões
npm install <package>@latest
```

> **IMPORTANTE**: Manter Prisma na versão 6.x se houver problemas de compatibilidade com Bun. A versão 6.18.0 é estável.

### 3.4 Resolver conflito ioredis + BullMQ

Se usar BullMQ, alinhar versão do ioredis:

```bash
npm install ioredis@5.8.2
```

> **Motivo**: BullMQ inclui ioredis como dependência interna. Versões diferentes causam erro de tipos TypeScript.

---

## 4. Fase 2: Migração de Bibliotecas Problemáticas

### 4.1 Substituir xlsx por exceljs

A biblioteca `xlsx` tem problemas de segurança e tipos. Migrar para `exceljs`:

```bash
npm uninstall xlsx
npm install exceljs
```

### 4.2 Atualizar código de importação Excel

**Antes (xlsx):**
```typescript
import * as XLSX from 'xlsx'

// Leitura
const workbook = XLSX.read(buffer, { type: 'buffer' })
const sheet = workbook.Sheets[workbook.SheetNames[0]]
const data = XLSX.utils.sheet_to_json(sheet)

// Escrita
const ws = XLSX.utils.json_to_sheet(data)
const wb = XLSX.utils.book_new()
XLSX.utils.book_append_sheet(wb, ws, 'Sheet1')
const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' })
```

**Depois (exceljs):**
```typescript
import ExcelJS from 'exceljs'

// Leitura
const workbook = new ExcelJS.Workbook()
await workbook.xlsx.load(buffer)
const worksheet = workbook.worksheets[0]
const data: any[] = []
worksheet.eachRow((row, rowNumber) => {
  if (rowNumber > 1) { // Pular cabeçalho
    data.push({
      col1: row.getCell(1).value,
      col2: row.getCell(2).value,
    })
  }
})

// Escrita
const workbook = new ExcelJS.Workbook()
const worksheet = workbook.addWorksheet('Sheet1')
worksheet.columns = [
  { header: 'Col1', key: 'col1' },
  { header: 'Col2', key: 'col2' },
]
worksheet.addRows(data)
const buffer = await workbook.xlsx.writeBuffer()
```

### 4.3 Corrigir tipos do Recharts (se aplicável)

Se usar Recharts com Tooltip customizado:

```typescript
// Antes (erro de tipo)
contentStyle={{ backgroundColor: '#fff' }}

// Depois (correto)
contentStyle={{ backgroundColor: '#fff' } as React.CSSProperties}
```

---

## 5. Fase 3: Instalação do Bun e Migração

### 5.1 Remover node_modules e cache

```bash
rm -rf node_modules
rm -rf .next
npm cache clean --force
```

### 5.2 Instalar dependências com Bun

```bash
bun install
```

> Isso criará automaticamente o arquivo `bun.lock`

### 5.3 Remover dependências desnecessárias

```bash
# tsx não é mais necessário (Bun executa TS nativamente)
bun remove tsx

# dotenv não é mais necessário (Bun carrega .env nativamente)
bun remove dotenv
```

### 5.4 Adicionar tipos do Bun

```bash
bun add -d @types/bun
```

---

## 6. Fase 4: Configuração do Bun

### 6.1 Criar bunfig.toml

```toml
# bunfig.toml
# Bun Configuration
# https://bun.sh/docs/runtime/bunfig

[install]
# Use exact versions for reproducible builds
exact = true

# Prefer offline packages when available
prefer = "offline"

[install.lockfile]
# Save lockfile
save = true

[run]
# Silent mode for cleaner output
silent = false

# Bun reads .env files automatically in this order:
# .env.local, .env.development, .env.production, .env
```

---

## 7. Fase 5: Atualização do package.json

### 7.1 Atualizar todos os scripts

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "bun --bun next start",
    "lint": "bun eslint",
    "lint:fix": "bun eslint --fix",
    "format": "bun prettier --write \"**/*.{js,jsx,ts,tsx,json,css,scss,md}\"",
    "format:check": "bun prettier --check \"**/*.{js,jsx,ts,tsx,json,css,scss,md}\"",
    "format:all": "bun run format && bun run lint:fix",
    "check": "bun run format:check && bun run lint",
    "workers": "bun run lib/queue/start-workers.ts",
    "workers:prod": "bun run lib/queue/start-workers.ts",
    "db:generate": "bunx --bun prisma generate",
    "db:push": "bunx --bun prisma db push",
    "db:migrate": "bunx --bun prisma migrate dev",
    "db:studio": "bunx --bun prisma studio",
    "prepare": "husky",
    "postinstall": "bunx --bun prisma generate"
  }
}
```

### 7.2 Notas importantes sobre scripts

| Script | Comando | Explicação |
|--------|---------|------------|
| `dev` | `next dev --turbopack` | Turbopack para dev rápido |
| `build` | `next build` | **SEM** `bun --bun` (causa erro de prerender) |
| `start` | `bun --bun next start` | **COM** `bun --bun` para runtime |
| `workers` | `bun run lib/queue/start-workers.ts` | Executa TS direto |
| `db:*` | `bunx --bun prisma ...` | Prisma via bunx |

> **CRÍTICO**: O comando `build` deve usar `next build` puro. Usar `bun --bun next build` causa erro de prerendering no global-error.tsx.

---

## 8. Fase 6: Atualização do Docker

### 8.1 Dockerfile completo para Bun

```dockerfile
# ==============================================================================
# Multi-Stage Dockerfile for Next.js 16 with Bun and Prisma
# Optimized for production deployment without source code exposure
# Supports: linux/amd64, linux/arm64
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Dependencies
# Install only production dependencies for smaller final image
# ------------------------------------------------------------------------------
FROM oven/bun:1.3-alpine AS deps

# Install libc6-compat for compatibility
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Copy package files and lockfile
COPY package.json bun.lock* ./

# Copy Prisma schema (required for prisma generate)
COPY prisma ./prisma/

# Install production dependencies only
# IMPORTANTE: Usar --ignore-scripts para evitar falha do postinstall em Docker
# e executar prisma generate manualmente após o install
RUN bun install --frozen-lockfile --production --ignore-scripts && \
    bunx prisma generate

# ------------------------------------------------------------------------------
# Stage 2: Builder
# Build the application with all dependencies
# ------------------------------------------------------------------------------
FROM oven/bun:1.3-alpine AS builder

# Install build dependencies
RUN apk add --no-cache libc6-compat

WORKDIR /app

# Copy package files and lockfile
COPY package.json bun.lock* ./

# Copy Prisma schema (required for prisma generate)
COPY prisma ./prisma/

# Install all dependencies (including devDependencies)
# IMPORTANTE: Usar --ignore-scripts para evitar falha do postinstall em Docker
# e executar prisma generate manualmente após o install
RUN bun install --frozen-lockfile --ignore-scripts && \
    bunx prisma generate

# Copy source code
COPY . .

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production

# Build Next.js application
RUN bun run build

# ------------------------------------------------------------------------------
# Stage 3: Runner
# Final production image with minimal footprint using Bun runtime
# ------------------------------------------------------------------------------
FROM oven/bun:1.3-alpine AS runner

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

# Copy production node_modules from deps stage
COPY --from=deps --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy Prisma files (needed for migrations at runtime)
COPY --from=builder --chown=nodejs:nodejs /app/prisma ./prisma

# Copy Next.js standalone build output
COPY --from=builder --chown=nodejs:nodejs /app/.next/standalone ./

# Copy static files
COPY --from=builder --chown=nodejs:nodejs /app/.next/static ./.next/static

# Copy public folder
COPY --from=builder --chown=nodejs:nodejs /app/public ./public

# Copy worker source files (Bun runs TypeScript natively)
COPY --from=builder --chown=nodejs:nodejs /app/lib ./lib

# Copy package.json and bun.lock for metadata
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nodejs:nodejs /app/bun.lock* ./

# Copy entrypoint script
COPY --chown=nodejs:nodejs docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy healthcheck script
COPY --chown=nodejs:nodejs healthcheck.ts ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Set hostname
ENV HOSTNAME="0.0.0.0"
ENV PORT=3000

# Health check using Bun
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD bun run healthcheck.ts || exit 1

# Use entrypoint script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command - run Next.js with Bun
CMD ["bun", "--bun", "server.js"]
```

### 8.2 docker-entrypoint.sh atualizado

```bash
#!/bin/sh
# ==============================================================================
# Docker Entrypoint Script for Manager DinastiAPI
# Handles database migrations and service startup with Bun runtime
# ==============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [ "$DEBUG" = "true" ]; then
        echo "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Extract host and port from DATABASE_URL
extract_db_host() {
    echo "$DATABASE_URL" | sed -n 's/.*@\([^:]*\):.*/\1/p'
}

extract_db_port() {
    echo "$DATABASE_URL" | sed -n 's/.*:\([0-9]*\)\/.*/\1/p'
}

# Extract host and port from REDIS_URL
extract_redis_host() {
    echo "$REDIS_URL" | sed -n 's/.*:\/\/\([^:]*\):.*/\1/p'
}

extract_redis_port() {
    echo "$REDIS_URL" | sed -n 's/.*:\([0-9]*\)$/\1/p'
}

# Wait for service to be ready
wait_for_service() {
    local host=$1
    local port=$2
    local service_name=$3
    local max_attempts=${4:-30}
    local attempt=1

    log_info "Waiting for $service_name at $host:$port..."

    while [ $attempt -le $max_attempts ]; do
        if nc -z "$host" "$port" > /dev/null 2>&1; then
            log_info "$service_name is ready!"
            return 0
        fi

        log_warn "Attempt $attempt/$max_attempts: $service_name not ready yet, waiting..."
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "Failed to connect to $service_name after $max_attempts attempts"
    return 1
}

# Detect if running in worker mode
is_worker_mode() {
    for arg in "$@"; do
        if echo "$arg" | grep -q "start-workers"; then
            return 0
        fi
    done
    return 1
}

# Main entrypoint logic
main() {
    log_info "=============================================="
    log_info "Manager DinastiAPI - Starting with Bun Runtime"
    log_info "=============================================="
    log_info "Bun version: $(bun --version)"

    # Detect mode
    SKIP_MIGRATIONS=false
    if is_worker_mode "$@"; then
        log_info "🔧 Worker mode detected"
        SKIP_MIGRATIONS=true
    else
        log_info "🚀 Application mode detected"
    fi

    # Check if DATABASE_URL is set
    if [ -z "$DATABASE_URL" ]; then
        log_error "DATABASE_URL environment variable is not set"
        exit 1
    fi

    # Extract database connection details
    DB_HOST=$(extract_db_host)
    DB_PORT=$(extract_db_port)

    if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ]; then
        log_warn "Could not extract database host/port from DATABASE_URL"
        log_warn "Assuming database is already accessible..."
    else
        # Wait for PostgreSQL
        wait_for_service "$DB_HOST" "$DB_PORT" "PostgreSQL" 30 || exit 1
    fi

    # Check if REDIS_URL is set (required for workers, optional for app)
    if [ -n "$REDIS_URL" ]; then
        REDIS_HOST=$(extract_redis_host)
        REDIS_PORT=$(extract_redis_port)

        if [ -z "$REDIS_HOST" ] || [ -z "$REDIS_PORT" ]; then
            log_warn "Could not extract Redis host/port from REDIS_URL"
        else
            # Wait for Redis (critical for workers)
            if is_worker_mode "$@"; then
                wait_for_service "$REDIS_HOST" "$REDIS_PORT" "Redis" 30 || exit 1
            else
                wait_for_service "$REDIS_HOST" "$REDIS_PORT" "Redis" 10 || {
                    log_warn "Redis is not available, but continuing anyway..."
                }
            fi
        fi
    else
        if is_worker_mode "$@"; then
            log_error "REDIS_URL is required for worker mode"
            exit 1
        fi
        log_warn "REDIS_URL not set, skipping Redis connectivity check"
    fi

    # Run Prisma migrations (skip for workers)
    if [ "$SKIP_MIGRATIONS" = "true" ]; then
        log_info "⏭️  Skipping Prisma migrations (worker mode)"
    else
        log_info "Running Prisma migrations..."
        if bunx --bun prisma migrate deploy; then
            log_info "✅ Migrations completed successfully"
        else
            log_error "❌ Migration failed"
            exit 1
        fi
    fi

    # Log startup information
    log_info "----------------------------------------------"
    log_info "Environment: $NODE_ENV"
    log_info "Timezone: $TZ"
    log_info "Port: $PORT"
    log_info "----------------------------------------------"

    # Execute the main command
    log_info "Starting application: $*"
    exec "$@"
}

# Run main function with all arguments
main "$@"
```

### 8.3 healthcheck.ts (Bun nativo)

```typescript
/**
 * ===========================================================================
 * Health Check Script for Docker (Bun Native)
 * ===========================================================================
 *
 * This script performs HTTP health checks on the Next.js application.
 * Used by Docker HEALTHCHECK directive to determine container health.
 *
 * Exit codes:
 * - 0: Application is healthy
 * - 1: Application is unhealthy
 */

const HOST = Bun.env.HOSTNAME || "localhost"
const PORT = Bun.env.PORT || "3000"
const TIMEOUT = 5000 // 5 seconds timeout
const PATH = "/" // Health check endpoint

async function performHealthCheck(): Promise<void> {
  const url = `http://${HOST}:${PORT}${PATH}`
  const startTime = Date.now()

  try {
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), TIMEOUT)

    const response = await fetch(url, {
      method: "GET",
      signal: controller.signal,
    })

    clearTimeout(timeoutId)

    const responseTime = Date.now() - startTime

    // Accept any 2xx or 3xx status codes (including redirects)
    const isHealthy = response.status >= 200 && response.status < 400

    if (isHealthy) {
      console.log(
        `[HEALTHCHECK] OK - Status: ${response.status}, Response time: ${responseTime}ms`
      )
      process.exit(0)
    } else {
      console.error(
        `[HEALTHCHECK] FAILED - Status: ${response.status}, Response time: ${responseTime}ms`
      )
      process.exit(1)
    }
  } catch (error) {
    const responseTime = Date.now() - startTime

    if (error instanceof Error) {
      if (error.name === "AbortError") {
        console.error(
          `[HEALTHCHECK] TIMEOUT - Request timed out after ${responseTime}ms`
        )
      } else {
        console.error(
          `[HEALTHCHECK] ERROR - ${error.message}, Response time: ${responseTime}ms`
        )
      }
    } else {
      console.error(
        `[HEALTHCHECK] ERROR - Unknown error, Response time: ${responseTime}ms`
      )
    }

    process.exit(1)
  }
}

// Run health check
performHealthCheck()
```

---

## 9. Fase 7: Atualização do CI/CD

### 9.1 GitHub Actions - release.yml

> **IMPORTANTE**: semantic-release requer Node.js ^22.14.0 ou >= 24.10.0. Portanto, é necessário configurar TANTO Node.js quanto Bun no workflow.

```yaml
name: Release

on:
  push:
    branches:
      - main
      - beta
      - alpha
  workflow_dispatch: {}

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  semantic-release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Setup Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest

      - name: Install dependencies
        run: bun install --frozen-lockfile

      - name: Semantic Release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          DOCKERHUB_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
          GITHUB_REPOSITORY: ${{ github.repository }}
        run: npx semantic-release
```

> **Nota**: O `bun install` é usado para instalar dependências (mais rápido), mas `npx semantic-release` é usado para execução pois semantic-release requer Node.js 22+.

### 9.2 docker-build.yml (não precisa alteração)

O workflow de Docker build não precisa ser alterado pois ele apenas executa o Dockerfile, que já foi atualizado para Bun.

---

## 10. Fase 8: Limpeza de Arquivos Obsoletos

### 10.1 Arquivos para deletar

```bash
# Healthcheck antigo (substituído por .ts)
rm healthcheck.js

# Lockfile do npm (substituído por bun.lock)
rm package-lock.json

# Config de build de workers (Bun executa TS nativo)
rm tsconfig.workers.json

# Pasta de workers compilados (não mais necessária)
rm -rf dist/
```

### 10.2 Verificar .gitignore

Garantir que os seguintes itens estejam no `.gitignore`:

```gitignore
# Dependencies
node_modules/

# Build output
.next/
dist/

# Bun
bun.lockb

# Environment
.env
.env.local
.env.*.local
```

---

## 11. Fase 9: Correções de Compatibilidade

### 11.1 Corrigir global-error.tsx (prerendering)

Se o build falhar com erro de prerendering no `global-error.tsx`, simplificar para usar inline styles:

```typescript
'use client'

interface GlobalErrorProps {
  error: Error & { digest?: string }
  reset: () => void
}

export default function GlobalError({ error, reset }: GlobalErrorProps) {
  return (
    <html lang="pt-BR">
      <body>
        <div
          style={{
            minHeight: '100vh',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            backgroundColor: '#0a0a0a',
            color: '#fafafa',
            fontFamily: 'system-ui, sans-serif',
          }}
        >
          <div style={{ textAlign: 'center', padding: '2rem' }}>
            <h1 style={{ fontSize: '2rem', marginBottom: '1rem' }}>
              Algo deu errado!
            </h1>
            <p style={{ marginBottom: '2rem', opacity: 0.7 }}>
              {error.message || 'Ocorreu um erro inesperado.'}
            </p>
            <button
              onClick={reset}
              style={{
                padding: '0.75rem 1.5rem',
                backgroundColor: '#3b82f6',
                color: 'white',
                border: 'none',
                borderRadius: '0.5rem',
                cursor: 'pointer',
                fontSize: '1rem',
              }}
            >
              Tentar novamente
            </button>
          </div>
        </div>
      </body>
    </html>
  )
}
```

### 11.2 BullMQ + Redis (manter ioredis)

**IMPORTANTE**: O cliente Redis nativo do Bun (`Bun.redis`) NÃO é compatível com BullMQ. Manter `ioredis`:

```bash
bun add ioredis@5.8.2
```

---

## 12. Fase 10: Testes e Validação

### 12.1 Testar build

```bash
bun run build
```

**Esperado**: Build completo sem erros

### 12.2 Testar desenvolvimento

```bash
bun run dev
```

**Esperado**: Servidor inicia em http://localhost:3000

### 12.3 Testar lint

```bash
bun run lint
```

### 12.4 Testar Prisma

```bash
bun run db:generate
bun run db:studio
```

### 12.5 Testar workers (se aplicável)

```bash
bun run workers
```

### 12.6 Testar Docker build

```bash
docker build -t test-bun .
docker run --rm test-bun bun --version
```

---

## 13. Commits Recomendados

Seguir ordem e formato de commits convencionais:

### Commit 1: Migração de biblioteca Excel
```bash
git add app/actions/contacts.ts app/api/campaigns/export/route.ts components/campaign/export-data.tsx components/campaign/import-excel-dialog.tsx

git commit -m "refactor(excel): migrate from xlsx to exceljs

- Replace xlsx library with exceljs for better TypeScript support
- Update import/export functions to use exceljs API
- Improve Excel file generation with proper typing
- Fix buffer handling for file downloads

BREAKING CHANGE: xlsx library replaced with exceljs"
```

### Commit 2: Correções TypeScript
```bash
git add components/campaign/charts/status-distribution.tsx app/global-error.tsx

git commit -m "fix(ui): resolve TypeScript type errors

- Fix Recharts Tooltip contentStyle type in status-distribution chart
- Simplify global-error.tsx to use inline styles
- Fix prerendering compatibility with Bun runtime"
```

### Commit 3: Migração para Bun
```bash
git add package.json bun.lock bunfig.toml

git commit -m "build(bun): migrate from npm to bun runtime

- Replace npm with bun as package manager
- Add bun.lock lockfile
- Create bunfig.toml configuration
- Update all scripts to use bun commands
- Remove dotenv (bun loads .env natively)
- Add @types/bun for TypeScript support
- Remove tsx dependency (bun runs TS natively)

BREAKING CHANGE: Project now requires Bun runtime instead of Node.js"
```

### Commit 4: Atualização Docker
```bash
git add Dockerfile docker-entrypoint.sh healthcheck.ts

git commit -m "build(docker): update container configuration for bun

- Use oven/bun:1.3-alpine as base image
- Update docker-entrypoint.sh to use bunx commands
- Create healthcheck.ts using Bun native APIs
- Copy worker source files instead of compiled dist
- Optimize multi-stage build for Bun runtime"
```

### Commit 5: Atualização CI/CD
```bash
git add .github/workflows/release.yml

git commit -m "ci(release): update workflow to use bun

- Replace actions/setup-node with oven-sh/setup-bun@v2
- Use bun install --frozen-lockfile
- Use bunx for semantic-release execution"
```

### Commit 6: Limpeza
```bash
git add healthcheck.js package-lock.json tsconfig.workers.json

git commit -m "chore: remove obsolete files after bun migration

- Remove healthcheck.js (replaced by healthcheck.ts)
- Remove package-lock.json (replaced by bun.lock)
- Remove tsconfig.workers.json (bun runs TS natively)"
```

---

## 14. Troubleshooting

### Erro: "Lock file already exists"

```bash
rm -rf .next
bun run build
```

### Erro: "ioredis type mismatch with BullMQ"

```bash
bun add ioredis@5.8.2
```

### Erro: "prerender error in global-error.tsx"

Usar `next build` em vez de `bun --bun next build` no script de build.

### Erro: "Cannot find module @types/bun"

```bash
bun add -d @types/bun
```

### Erro: "dotenv is not defined"

Remover imports de dotenv - Bun carrega .env automaticamente.

### Erro: "tsx command not found"

Remover tsx - Bun executa TypeScript nativamente.

### Erro: "postinstall script exited with 1" no Docker

O script postinstall que executa `prisma generate` pode falhar no Docker por questões de timing ou ambiente. Solução:

```dockerfile
# Usar --ignore-scripts e executar prisma generate manualmente
RUN bun install --frozen-lockfile --ignore-scripts && \
    bunx prisma generate
```

### Erro: "prisma/schema.prisma: file not found" no Docker

Copiar a pasta prisma ANTES de executar `bun install`:

```dockerfile
COPY prisma ./prisma/
RUN bun install --frozen-lockfile --ignore-scripts && \
    bunx prisma generate
```

### Build muito lento ou travando

Verificar memória disponível. Next.js build requer ~4GB RAM mínimo.

---

## 15. Referência de Arquivos

### Estrutura final do projeto

```
project/
├── .github/
│   └── workflows/
│       ├── release.yml          # ✅ Atualizado para Bun
│       └── docker-build.yml     # ✅ Usa Dockerfile (não precisa mudar)
├── app/
│   ├── global-error.tsx         # ✅ Simplificado (inline styles)
│   └── ...
├── lib/
│   └── queue/
│       └── start-workers.ts     # ✅ Executado direto pelo Bun
├── prisma/
│   └── schema.prisma
├── Dockerfile                   # ✅ Usa oven/bun:1.3-alpine
├── docker-entrypoint.sh         # ✅ Usa bunx --bun prisma
├── healthcheck.ts               # ✅ Novo (Bun nativo)
├── package.json                 # ✅ Scripts atualizados
├── bun.lock                     # ✅ Novo lockfile
├── bunfig.toml                  # ✅ Nova configuração
└── next.config.ts               # ✅ output: "standalone"
```

### Arquivos removidos

```
❌ healthcheck.js        → Substituído por healthcheck.ts
❌ package-lock.json     → Substituído por bun.lock
❌ tsconfig.workers.json → Não necessário (Bun executa TS)
❌ dist/                 → Não necessário (workers executam direto)
```

---

## Checklist Final

- [ ] Bun instalado globalmente
- [ ] Dependências atualizadas (npm outdated → 0)
- [ ] Vulnerabilidades corrigidas (npm audit → 0)
- [ ] xlsx substituído por exceljs
- [ ] ioredis alinhado com BullMQ (5.8.2)
- [ ] node_modules removido e reinstalado com bun
- [ ] tsx removido
- [ ] dotenv removido
- [ ] @types/bun adicionado
- [ ] bunfig.toml criado
- [ ] package.json scripts atualizados
- [ ] Dockerfile atualizado para oven/bun
- [ ] docker-entrypoint.sh usa bunx
- [ ] healthcheck.ts criado
- [ ] release.yml usa oven-sh/setup-bun
- [ ] Arquivos obsoletos removidos
- [ ] Build funciona: `bun run build`
- [ ] Dev funciona: `bun run dev`
- [ ] Commits criados seguindo convenções

---

**Autor**: Claude Code Agent  
**Versão**: 1.1  
**Última atualização**: 07 Janeiro 2026

### Changelog
- **v1.1**: Adicionada correção `--ignore-scripts` no Dockerfile para resolver falhas de postinstall
- **v1.0**: Versão inicial do guia de migração
