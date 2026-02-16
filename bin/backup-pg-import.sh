#!/bin/bash

set -Eeuo pipefail

source .env

COMPOSE_SERVICE="${PG_BACKUP_COMPOSE_SERVICE:-postgres}"
BACKUP_ROOT="${PG_BACKUP_BACKUP_DIR:-./backups}"

DOCKER_COMPOSE="docker compose exec -T ${COMPOSE_SERVICE}"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <timestamp>"
  exit 1
fi

TIMESTAMP="$1"
BACKUP_DIR="${BACKUP_ROOT}/${TIMESTAMP}"

if [[ ! -d "${BACKUP_DIR}" ]]; then
  echo "Backup directory not found: ${BACKUP_DIR}"
  exit 1
fi

log() {
  echo "[$(date -u +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting restore from ${BACKUP_DIR}"

# ---- Restore global roles ----
if [[ -f "${BACKUP_DIR}/00_globals.sql" ]]; then
  log "Restoring global roles..."
  cat "${BACKUP_DIR}/00_globals.sql" | $DOCKER_COMPOSE psql -U postgres -d postgres
else
  log "No globals.sql found — skipping role restore."
fi

# ---- Restore each database dump ----
for DUMP in "${BACKUP_DIR}"/*.dump; do
  DB_NAME="$(basename "${DUMP}" .dump)"

  log "Preparing database: ${DB_NAME}"

  # Terminate existing connections
  $DOCKER_COMPOSE psql -U postgres -d postgres -c \
    "SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = '${DB_NAME}'
      AND pid <> pg_backend_pid();" || true

  # Drop database if exists
  $DOCKER_COMPOSE psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS \"${DB_NAME}\";"

  # Recreate database
  $DOCKER_COMPOSE psql -U postgres -d postgres -c "CREATE DATABASE \"${DB_NAME}\";"

  log "Restoring database: ${DB_NAME}"

  cat "${DUMP}" | $DOCKER_COMPOSE pg_restore -U postgres -d "${DB_NAME}" --no-owner --role=postgres --clean --if-exists
done

log "Restore completed successfully."
