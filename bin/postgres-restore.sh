#!/bin/bash

set -Eeuo pipefail
source .env

server_hostname="${SERVER_HOSTNAME:?}"
compose_service="${PG_BACKUP_COMPOSE_SERVICE:-postgres}"
backup_dir="${PG_BACKUP_BACKUP_DIR:-./backups}"

# TODO: compose file MUST use .env
compose="docker compose -f compose.${server_hostname}.yml exec -T ${compose_service}"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <timestamp>"
  exit 1
fi

timestamp="$1"
backup_dir="${backup_dir}/${timestamp}"

if [[ ! -d "${backup_dir}" ]]; then
  echo "Backup directory not found: ${backup_dir}"
  exit 1
fi

log() {
  echo "[$(date -u +'%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting restore from ${backup_dir}"

# ---- Restore global roles ----
if [[ -f "${backup_dir}/00_globals.sql" ]]; then
  log "Restoring global roles..."
  cat "${backup_dir}/00_globals.sql" | $compose psql -U postgres -d postgres
else
  log "No globals.sql found — skipping role restore."
fi

# ---- Restore each database dump ----
for dump in "${backup_dir}"/*.dump; do
  db_name="$(basename "${dump}" .dump)"

  log "Preparing database: ${db_name}"

  # Terminate existing connections
  $compose psql -U postgres -d postgres -c \
    "SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE datname = '${db_name}'
      AND pid <> pg_backend_pid();" || true

  # Drop database if exists
  $compose psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS \"${db_name}\";"

  # Recreate database
  $compose psql -U postgres -d postgres -c "CREATE DATABASE \"${db_name}\";"

  log "Restoring database: ${db_name}"

  cat "${dump}" | $compose pg_restore -U postgres -d "${db_name}" --no-owner --role=postgres --clean --if-exists
done

log "Restore completed successfully."
