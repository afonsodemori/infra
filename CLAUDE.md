# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Infrastructure-as-code repository for managing a multi-service production environment using Docker Compose and Nginx as a reverse proxy. Supports multiple deployment targets (Ion VPS, Oracle Cloud) with shared service definitions.

## Common Commands

All commands require `SERVER_HOSTNAME` to be set in `.env` (e.g., `ion-vps`, `oci-prod`, `oci-staging`, `oci-labs`). The Makefile selects `compose.$(SERVER_HOSTNAME).yml` automatically.

```bash
make up                        # Start all services + deploy default pages
make down                      # Stop all services
make logs                      # Tail logs for all services
make nginx-reload              # Test nginx config, reload, and deploy default pages
make docker/update-images      # Pull latest images and restart
make docker/force-recreate     # Force recreate all containers
make deploy-default            # Deploy 404 page and health check to nginx container
```

### Devcontainer Image Builds

```bash
make devcontainers/debian-13/build      # Build and push Debian 13 image
make devcontainers/go-1-26/build        # Build and push Go 1.26 image
make devcontainers/node-24/build        # Build and push Node.js 24 image
```

### Utility Scripts

```bash
bin/backup-pg-export.sh        # Export PostgreSQL backup
bin/backup-pg-import.sh        # Import PostgreSQL backup
bin/certbot.sh                 # SSL certificate operations
bin/install-crontab.sh         # Install crontab from config/crontab
bin/install-data-dirs.sh       # Create required data directories
bin/install-packages.sh        # Install host packages
```

## Architecture

### Deployment Environments

Each environment has a top-level compose file that wires everything together:

| File                      | Environment                  |
| ------------------------- | ---------------------------- |
| `compose.ion-vps.yml`     | Ion VPS (primary production) |
| `compose.oci-prod.yml`    | Oracle Cloud Production      |
| `compose.oci-staging.yml` | Oracle Cloud Staging         |
| `compose.oci-labs.yml`    | Oracle Cloud Labs            |

These use Docker Compose `include:` to pull in individual service definitions from `docker/compose/`.

### Service Definitions

Each service lives in its own file under `docker/compose/`:

- `compose.database.yml` — PostgreSQL (host-bound to localhost:5432 only)
- `compose.{service}-{env}.yml` — Application services (ephemeral, jrbaena, meteosaucana, mycrew-\*, afonsodev, fnscli, psono)
- `compose.{tool}.yml` — Infrastructure tools (certbot, pgadmin, wgeasy, uptime-kuma, alloy)

Adding a new service means creating a file in `docker/compose/` and adding an `include:` entry to the relevant top-level compose file(s).

### Nginx Reverse Proxy

`docker/nginx/` contains:

- `nginx.conf` — Main config
- `sites-available/` — One `.conf` per vhost/application
- `sites-enabled/` — Symlinks to enabled sites (mounted as `conf.d`)
- `snippets/security.conf`, `proxy.conf`, `ssl-common.conf` — Reusable includes
- `html/` — Static files served by nginx (404 page, health check JSON)

To add a new vhost: create in `sites-available/`, symlink in `sites-enabled/`, run `make nginx-reload`.

### SSL Certificates

Managed by Certbot via Cloudflare DNS-01 challenge. Cert data is stored in the `certbot-data` Docker volume, mounted read-only into nginx. Renewal runs every Wednesday at 04:37 via cron (`config/crontab`).

### Observability

- **Grafana Alloy** — Collects and ships logs to a Loki endpoint
- **Uptime Kuma** — Service uptime monitoring
- **Health checks** — `/health.json` served by nginx for each service

### Devcontainer Images

Custom base images defined in `docker/registry/devcontainers/`:

- `debian/debian-13/` — Base Debian 13 image
- `golang/go-1-26/` — Go development image (extends debian-13)
- `node/node-24/` — Node.js development image (extends debian-13)

Built and pushed to `ghcr.io/afonsodemori/devcontainers/` via GitHub Actions (`.github/workflows/devcontainers.yml`). The workflow is manually triggered and supports building individual images or all at once.

### Environment Variables

Copy `.env.ion-vps.example` (or the relevant `.env.{provider}.example`) to `.env` and fill in values. Key variables:

- `SERVER_HOSTNAME` — Controls which top-level compose file `make` uses
- `INFRA_DIR`, `DATA_DIR` — Host path configuration
- `NGINX_VERSION` — Nginx container image tag
- `CERTBOT_CLOUDFLARE_API_TOKEN` — For DNS-01 certificate renewal
- `DATABASE_POSTGRES_PASSWORD` — Shared database password
- `ALLOY_GRAFANA_*` — Grafana Cloud credentials for log shipping
