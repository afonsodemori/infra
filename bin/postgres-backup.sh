#!/bin/bash

set -Eeuo pipefail
source .env

server_hostname="${SERVER_HOSTNAME:?}"
compose_service="${PG_BACKUP_COMPOSE_SERVICE:-postgres}"
backup_dir="${PG_BACKUP_BACKUP_DIR:-./backups}"
retention_days="${PG_BACKUP_RETENTION_DAYS:-7}"

timestamp="$(date -u +%Y%m%d-%H%M%S)"
# TODO: compose file MUST use .env
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
echo "${db_list}"

# ---- Dump global roles ----
log "Dumping global roles..."
$compose pg_dumpall -U postgres --globals-only > "${backup_dir}/${timestamp}/00_globals.sql"

# ---- Dump each database ----
for db in ${db_list}; do
  log "Dumping database: ${db}"
  $compose pg_dump -U postgres -Fc -d "${db}" > "${backup_dir}/${timestamp}/${db}.dump"
done

# ---- Generate tarball ----
log "Compressing backup directory..."
tar -czf "${backup_dir}/${timestamp}.tgz" -C "${backup_dir}" "${timestamp}"
rm -rf "${backup_dir}/${timestamp}"
log "Backup complete: ${backup_dir}/${timestamp}.tgz"

# ---- Upload to R2 ----
wrangler r2 object put --remote \
  backups/postgres_${server_hostname}_${timestamp}.tgz \
  --file "${backup_dir}/${timestamp}.tgz"

# TODO: retention policy for R2 objects (list + delete) and local tarballs
# ---- Retention policy ----
# log "Cleaning backups older than ${retention_days} days..."

# find "${backup_dir}" \
#   -mindepth 1 -maxdepth 1 -type d \
#   -mtime +${retention_days} \
#   -exec rm -rf {} \;

# log "Backup finished successfully."
