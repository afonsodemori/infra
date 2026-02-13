#!/usr/bin/env bash
set -Eeuo pipefail

COMPOSE_SERVICE="${PG_BACKUP_COMPOSE_SERVICE:-postgres}"
BACKUP_ROOT="${PG_BACKUP_BACKUP_DIR:-./backups}"
RETENTION_DAYS=${PG_BACKUP_RETENTION_DAYS:-7}

TIMESTAMP="$(date -u +%Y%m%d_%H%M%S)"
DOCKER_COMPOSE="docker compose exec -T ${COMPOSE_SERVICE}"

mkdir -p "${BACKUP_ROOT}/${TIMESTAMP}"

log() {
  echo "[$(date -u +%Y-%m-%d %H:%M:%S)] $*"
}

log "Discovering user databases from pg_database..."

DB_LIST=$($DOCKER_COMPOSE \
  psql -U postgres -d postgres -Atc "
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datallowconn = true
      AND datname NOT IN ('postgres')
    ORDER BY datname;
")

if [[ -z "${DB_LIST}" ]]; then
  log "No user databases found. Exiting."
  exit 0
fi

log "Databases detected:"
echo "${DB_LIST}"

# ---- Dump global roles ----
log "Dumping global roles..."
$DOCKER_COMPOSE pg_dumpall -U postgres --globals-only > "${BACKUP_ROOT}/${TIMESTAMP}/00_globals.sql"

# ---- Dump each database ----
for DB in ${DB_LIST}; do
  log "Dumping database: ${DB}"
  $DOCKER_COMPOSE pg_dump -U postgres -Fc -d "${DB}" > "${BACKUP_ROOT}/${TIMESTAMP}/${DB}.dump"
done

# ---- Upload to R2 ----
log "Uploading backup set to R2..."
rclone copy "${BACKUP_ROOT}/${TIMESTAMP}" "r2:postgres/${TIMESTAMP}"

log "Upload completed."

# ---- Retention policy ----
log "Cleaning backups older than ${RETENTION_DAYS} days..."

find "${BACKUP_ROOT}" \
  -mindepth 1 -maxdepth 1 -type d \
  -mtime +${RETENTION_DAYS} \
  -exec rm -rf {} \;

log "Backup finished successfully."
