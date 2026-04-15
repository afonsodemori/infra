#!/bin/bash

set -Eeuo pipefail
source .env

# TODO: find a better way to ensure the correct node version is used for wrangler without relying on hardcoded paths
export PATH="/home/ops/.nvm/versions/node/v24.14.1/bin:${PATH}"

server_hostname="${SERVER_HOSTNAME:?}"
compose_service="${PG_BACKUP_COMPOSE_SERVICE:-postgres}"
backup_dir="${PG_BACKUP_BACKUP_DIR:-./backups}"
retention_days="${PG_BACKUP_RETENTION_DAYS:-7}"

timestamp="$(date -u +%Y%m%d-%H%M%S)"
compose="docker compose -f compose.${server_hostname}.yml exec -T ${compose_service}"

mkdir -p "${backup_dir}/${timestamp}"

log() {
  echo "[$(date -u +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Discovering user databases from pg_database..."

db_list=$($compose \
  psql -U postgres -d postgres -Atc "
    SELECT datname
    FROM pg_database
    WHERE datistemplate = false
      AND datallowconn = true
      AND datname NOT IN ('postgres')
    ORDER BY datname;
")

if [[ -z "${db_list}" ]]; then
  log "No user databases found. Exiting."
  exit 0
fi

log "Databases detected:"
while IFS= read -r db; do log "  - ${db}"; done <<<"${db_list}"

# ---- Dump global roles ----
log "Dumping global roles (excluding postgres)..."
$compose pg_dumpall -U postgres --globals-only |
  { grep -vE '^(CREATE|ALTER) ROLE postgres( |;)' || true; } \
    >"${backup_dir}/${timestamp}/00_globals.sql"

# ---- Dump each database ----
while IFS= read -r db; do
  log "Dumping database: ${db}"
  $compose pg_dump -U postgres -Fc -d "${db}" >"${backup_dir}/${timestamp}/${db}.dump" </dev/null
done <<<"${db_list}"

# ---- Generate tarball ----
log "Compressing backup directory..."
tar -czf "${backup_dir}/${timestamp}.tgz" -C "${backup_dir}" "${timestamp}"
rm -rf "${backup_dir}/${timestamp}"
log "Backup complete: ${backup_dir}/${timestamp}.tgz"

# ---- Upload to R2 ----
r2_key="backup/${timestamp}_postgres_${server_hostname}.tgz"
log "Uploading to R2: ${r2_key}"
wrangler r2 object put --remote "${r2_key}" --file "${backup_dir}/${timestamp}.tgz"

# ---- Retention policy ----
log "Cleaning local tarballs older than ${retention_days} days..."

find "${backup_dir}" \
  -mindepth 1 -maxdepth 1 -type f -name "*.tgz" \
  -mtime +${retention_days} \
  -print -delete

log "Backup finished successfully."
