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

# ---- Discover backup contents ----
shopt -s nullglob
dump_files=("${backup_dir}"/*.dump)
shopt -u nullglob

log "Backup contents:"
if [[ -f "${backup_dir}/00_globals.sql" ]]; then
  log "  - roles (00_globals.sql): found"
else
  log "  - roles (00_globals.sql): not found"
fi
if [[ ${#dump_files[@]} -gt 0 ]]; then
  log "  - databases (${#dump_files[@]}):"
  for dump in "${dump_files[@]}"; do
    log "    - $(basename "${dump}" .dump)"
  done
else
  log "  - databases: none"
fi

# ---- Restore global roles ----
if [[ -f "${backup_dir}/00_globals.sql" ]]; then
  log "Restoring global roles..."

  # Snapshot existing roles before any changes so we know which ones are new
  existing_roles=$($compose psql -U postgres -d postgres -Atc "SELECT rolname FROM pg_roles;")

  # For existing roles: strip PASSWORD to preserve it; for new roles: keep PASSWORD so it is imported.
  # Log calls use >&2 so they go to stderr rather than into the psql pipe.
  while IFS= read -r line; do
    if [[ "$line" =~ ^ALTER\ ROLE\ [\"]*([^\"\ ]+)[\"]*\  ]]; then
      role_name="${BASH_REMATCH[1]}"
      if grep -qxF "${role_name}" <<<"${existing_roles}"; then
        log "  - ${role_name}: exists — updating attributes, preserving password" >&2
        line="$(printf '%s' "$line" | sed -E "s/ PASSWORD '[^']*'//g")"
      else
        log "  - ${role_name}: new — importing with password" >&2
      fi
    fi
    printf '%s\n' "$line"
  done <"${backup_dir}/00_globals.sql" | $compose psql -U postgres -d postgres

  log "Role restore complete."
else
  log "No globals.sql found — skipping role restore."
fi

# ---- Restore each database dump ----
if [[ ${#dump_files[@]} -eq 0 ]]; then
  log "No database dumps found — skipping database restore."
else
  log "Restoring ${#dump_files[@]} database(s)..."

  for dump in "${dump_files[@]}"; do
    db_name="$(basename "${dump}" .dump)"

    log "  [${db_name}] Terminating existing connections..."
    $compose psql -U postgres -d postgres -c \
      "SELECT pg_terminate_backend(pid)
      FROM pg_stat_activity
      WHERE datname = '${db_name}'
        AND pid <> pg_backend_pid();" || true

    log "  [${db_name}] Dropping and recreating database..."
    $compose psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS \"${db_name}\";"
    $compose psql -U postgres -d postgres -c "CREATE DATABASE \"${db_name}\";"

    log "  [${db_name}] Restoring data..."
    # Restore with original ownership; if a role no longer exists, pg_restore warns and
    # leaves the object owned by the session user (postgres). Exit code 1 on warnings is expected.
    $compose pg_restore -U postgres -d "${db_name}" <"${dump}" || true

    log "  [${db_name}] Done."
  done
fi

log "Restore completed successfully."
