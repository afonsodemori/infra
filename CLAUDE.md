# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Infrastructure-as-code repository for managing a multi-service production environment using Docker Compose and Nginx as a reverse proxy. Supports multiple deployment targets (Oracle Cloud) with shared service definitions.

## Common Commands

All commands require `SERVER_HOSTNAME` to be set in `.env` (e.g., `oci-prod`, `oci-staging`, `oci-labs`). The Makefile selects `compose.$(SERVER_HOSTNAME).yml` automatically.

```bash
make up                        # Generate nginx assets, start all services, then test and reload nginx
make down                      # Stop all services
make logs                      # Tail logs for all services
make nginx-reload              # Generate nginx assets, test config, and reload
make docker/update-images      # Pull latest images (incl. ondemand profile), restart and reload nginx
make docker/force-recreate     # Force recreate all containers
make update-nginx-assets       # Generate health.json and 404.html into $DATA_DIR/nginx/dist
```

### Devcontainer Image Builds

```bash
make devcontainers/debian-13/build        # Build and push Debian 13 image
make devcontainers/go-1-27/build          # Build and push Go 1.27 image
make devcontainers/node-24/build          # Build and push Node.js 24 image
make devcontainers/debian-13/build-local  # Build locally without pushing
make devcontainers/go-1-27/build-local    # Build locally without pushing
make devcontainers/node-24/build-local    # Build locally without pushing
```

### Utility Scripts

```bash
bin/postgres-backup.sh                # Back up PostgreSQL into $PG_BACKUP_BACKUP_DIR/<timestamp>
bin/postgres-restore.sh <timestamp>   # Restore a PostgreSQL backup
bin/certbot.sh <cmd>                  # Run certbot (new/renew/revoke/delete reload nginx)
bin/create-server-health-check.sh     # Generate nginx assets (used by make update-nginx-assets)
bin/crontab-install.sh                # Install crontab from config/crontab.$SERVER_HOSTNAME
bin/install-data-dirs.sh              # Create required data directories
bin/install-packages.sh               # Install host packages
```

## Architecture

### Deployment Environments

Each environment has a top-level compose file that wires everything together:

| File                      | Environment             | Included services                                          |
| ------------------------- | ----------------------- | ---------------------------------------------------------- |
| `compose.oci-prod.yml`    | Oracle Cloud Production | afonsodev-production, jrbaena, meteosaucana, psono         |
| `compose.oci-staging.yml` | Oracle Cloud Staging    | afonsodev-preview, pgadmin, snippetbox                     |
| `compose.oci-labs.yml`    | Oracle Cloud Labs       | uptime-kuma, vpn                                           |

Every environment also includes `database`, `alloy` and `certbot`.

These files define the `nginx` service directly (with its volume mounts for certs, config, vhosts and generated assets) and use Docker Compose `include:` to pull in individual service definitions from `docker/compose/`.

### Service Definitions

Each service lives in its own file under `docker/compose/`:

- `compose.database.yml` — PostgreSQL (host-bound to localhost:5432 only)
- `compose.{service}-{env}.yml` — Application services (afonsodev, jrbaena, meteosaucana, mycrew). The mycrew files exist but are not currently included by any environment.
- `compose.snippetbox.yml` — Snippetbox app plus a temporary MySQL container (localhost:3306), pending migration to PostgreSQL
- `compose.{tool}.yml` — Tools (psono, certbot, pgadmin, vpn, uptime-kuma, alloy)

Some services have companion config subdirectories in `docker/compose/` (`alloy/`, `certbot/`, `pgadmin/`, `psono/`, `uptime-kuma/`) for their runtime configuration files.

Certbot uses the `ondemand` profile, so `make up` does not start it. It runs through `bin/certbot.sh`.

Adding a new service means creating a file in `docker/compose/` and adding an `include:` entry to the relevant top-level compose file(s).

### Nginx Reverse Proxy

`docker/nginx/` contains:

- `nginx.conf` — Main config
- `sites-available/` — One `.conf` per vhost/application
- `sites-enabled/` — Symlinks to enabled sites (mounted as `conf.d`). Git ignores its contents, so each server keeps its own symlinks.
- `snippets/security.conf`, `proxy.conf`, `ssl-common.conf` — Reusable includes
- `html/404.html` — 404 template (`{HOSTNAME}` placeholder)

`make update-nginx-assets` renders `404.html` and generates `health.json` into `$DATA_DIR/nginx/dist/`, which is mounted into the nginx container.

To add a new vhost: create in `sites-available/`, symlink in `sites-enabled/` on the server, run `make nginx-reload`.

Proxy to containers via a variable (`set $upstream http://<service>:<port>; proxy_pass $upstream;`), not a literal `proxy_pass http://<service>:<port>;`. With a variable, nginx re-resolves the name at request time through the `resolver` in `nginx.conf` (Docker DNS, `127.0.0.11`), so it doesn't keep stale IPs after a container is recreated or fail to start when an upstream is down. Passing a variable also changes how nginx handles a URI path in `proxy_pass`, so keep upstreams as bare `http://host:port`.

### SSL Certificates

Managed by Certbot via Cloudflare DNS-01 challenge. Cert data is stored in `$DATA_DIR/letsencrypt/data`, which is mounted read-only into nginx. Renewal runs via cron from the per-server `config/crontab.$SERVER_HOSTNAME`. Each server has its own schedule, and the same crontab also runs a PostgreSQL backup.

### Observability

- **Grafana Alloy** — Collects and ships logs to a Loki endpoint
- **Uptime Kuma** — Service uptime monitoring
- **Health checks** — `/health.json` served by nginx per server. pgadmin, psono and uptime-kuma also have their own `health.json`.

### Devcontainer Images

Custom base images defined in `docker/registry/devcontainers/`:

- `debian/debian-13/` — Base Debian 13 image
- `golang/go-1-27/` — Go development image (extends debian-13)
- `node/node-24/` — Node.js development image (extends debian-13)

Built and pushed to `ghcr.io/afonsodemori/devcontainers/` via GitHub Actions (`.github/workflows/devcontainers.yml`). The workflow is manually triggered and supports building individual images or all at once.

### Environment Variables

Copy the relevant `.env.{environment}.example` (e.g. `.env.oci-prod.example`) to `.env` and fill in values. Key variables:

- `SERVER_HOSTNAME` — Controls which top-level compose file and crontab are used
- `INFRA_DIR`, `DATA_DIR` — Host path configuration
- `NGINX_VERSION` — Nginx container image tag
- `CERTBOT_*` — Cloudflare API token, email and propagation delay for DNS-01 renewal
- `DATABASE_POSTGRES_PASSWORD`, `DATABASE_POSTGRES_VERSION` — Shared database
- `PG_BACKUP_*` — Backup directory, retention days and compose service for `bin/postgres-backup.sh`
- `ALLOY_GRAFANA_*` — Grafana Cloud credentials for log shipping
