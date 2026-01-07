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
