#!/bin/bash

set -Eeuo pipefail
source .env

server_hostname="${SERVER_HOSTNAME:?}"
compose_service="${PG_BACKUP_COMPOSE_SERVICE:-postgres}"
backup_dir="${PG_BACKUP_BACKUP_DIR:-./backups}"

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

  # Snapshot existing roles before any changes so we know which ones are new
  existing_roles=$($compose psql -U postgres -d postgres -Atc "SELECT rolname FROM pg_roles;")

  # For existing roles: strip PASSWORD to preserve it; for new roles: keep PASSWORD so it is imported
  while IFS= read -r line; do
    if [[ "$line" =~ ^ALTER\ ROLE\ [\"]*([^\"\ ]+)[\"]*\  ]]; then
      role_name="${BASH_REMATCH[1]}"
      if grep -qxF "${role_name}" <<<"${existing_roles}"; then
        line="$(printf '%s' "$line" | sed -E "s/ PASSWORD '[^']*'//g")"
      fi
    fi
    printf '%s\n' "$line"
  done <"${backup_dir}/00_globals.sql" | $compose psql -U postgres -d postgres
else
  log "No globals.sql found — skipping role restore."
fi

# ---- Restore each database dump ----
shopt -s nullglob
dump_files=("${backup_dir}"/*.dump)
shopt -u nullglob

if [[ ${#dump_files[@]} -eq 0 ]]; then
  log "No database dumps found in ${backup_dir} — skipping database restore."
else
  for dump in "${dump_files[@]}"; do
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

    # Restore with original ownership; if a role no longer exists, pg_restore warns and
    # leaves the object owned by the session user (postgres). Exit code 1 on warnings is expected.
    $compose pg_restore -U postgres -d "${db_name}" --clean --if-exists <"${dump}" || true
  done
fi

log "Restore completed successfully."
