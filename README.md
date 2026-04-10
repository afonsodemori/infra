# infra

Infrastructure-as-code for managing a multi-service production environment using Docker Compose and Nginx as a reverse proxy. Supports multiple deployment targets with shared service definitions.

Service status at: <https://status.afonso.dev>

## Environments

| Compose file              | Target                         |
| ------------------------- | ------------------------------ |
| `compose.ion-vps.yml`     | Ionos VPS (primary production) |
| `compose.oci-prod.yml`    | Oracle Cloud Production        |
| `compose.oci-staging.yml` | Oracle Cloud Staging           |
| `compose.oci-labs.yml`    | Oracle Cloud Labs              |

## Setup

1. Copy the example env file for your target environment:

   ```bash
   cp .env.ion-vps.example .env        # or .env.oci-prod.example, etc.
   ```

2. Fill in the required values in `.env`. At minimum:
   - `SERVER_HOSTNAME` — must match one of the environment names above (e.g. `ion-vps`)
   - `INFRA_DIR`, `DATA_DIR` — host paths for config and data
   - `NGINX_VERSION` — nginx image tag
   - `DATABASE_POSTGRES_PASSWORD`

3. Create required data directories:

   ```bash
   bin/install-data-dirs.sh
   ```

4. Install the crontab:

   ```bash
   bin/install-crontab.sh
   ```

## Common Commands

All commands require `SERVER_HOSTNAME` to be set in `.env`.

```bash
make up                       # Start all services and deploy default pages
make down                     # Stop all services
make logs                     # Tail logs for all services
make nginx-reload             # Test nginx config, reload, and redeploy default pages
make docker/update-images     # Pull latest images and restart
make docker/force-recreate    # Force recreate all containers
make deploy-default           # Deploy 404 page and health check to nginx
```

## Architecture

### Services

Individual service definitions live in `docker/compose/`:

| File                                          | Description                        |
| --------------------------------------------- | ---------------------------------- |
| `compose.database.yml`                        | PostgreSQL (localhost:5432 only)   |
| `compose.ephemeral-production.yml`            | ephemeral.afonso.dev web app       |
| `compose.jrbaena-production.yml`              | jrbaena.com web app                |
| `compose.meteosaucana-production.yml`         | meteosaucana.com web app           |
| `compose.mycrew-{production,staging,...}.yml` | MyCrew API (multiple environments) |
| `compose.afonsodev-production.yml`            | afonso.dev web + API               |
| `compose.fnscli-production.yml`               | fns-cli.afonso.dev documentation   |
| `compose.psono-production.yml`                | Psono password manager             |
| `compose.wgeasy.yml`                          | WireGuard Easy VPN                 |
| `compose.pgadmin.yml`                         | pgAdmin database UI                |
| `compose.uptime-kuma.yml`                     | Uptime Kuma monitoring             |
| `compose.alloy.yml`                           | Grafana Alloy log collector        |
| `compose.certbot.yml`                         | Certbot SSL certificate renewal    |

To add a new service: create a file in `docker/compose/`, then add an `include:` entry to the relevant top-level compose file(s).

### Nginx Reverse Proxy

`docker/nginx/` layout:

```
nginx.conf                  Main nginx config
sites-available/            One .conf per vhost
sites-enabled/              Symlinks to enabled vhosts (mounted as conf.d)
snippets/                   Reusable includes (security, proxy, ssl-common)
html/                       Static files (404 page, health.json)
```

To add a new vhost: create a config in `sites-available/`, symlink it in `sites-enabled/`, then run `make nginx-reload`.

### SSL Certificates

Managed by Certbot via Cloudflare DNS-01 challenge. Cert data is stored in the `certbot-data` Docker volume (mounted read-only into nginx). Renewal runs every Wednesday at 04:37 via cron (`config/crontab`).

### Observability

- **Grafana Alloy** — ships container logs to a Grafana Cloud Loki endpoint
- **Uptime Kuma** — service uptime monitoring dashboard
- **Health checks** — `/health.json` served by nginx per environment

## Utility Scripts

```bash
bin/backup-pg-export.sh     # Export a PostgreSQL backup
bin/backup-pg-import.sh     # Import a PostgreSQL backup
bin/certbot.sh              # SSL certificate operations
bin/install-crontab.sh      # Install crontab from config/crontab
bin/install-data-dirs.sh    # Create required host data directories
bin/install-packages.sh     # Install required host packages
```

## Devcontainer Images

Custom base images are defined in `docker/registry/devcontainers/` and published to `ghcr.io/afonsodemori/devcontainers/` via GitHub Actions.

| Image       | Base      | Make target                          |
| ----------- | --------- | ------------------------------------ |
| `debian-13` | Debian 13 | `make devcontainers/debian-13/build` |
| `go-1-26`   | debian-13 | `make devcontainers/go-1-26/build`   |
| `node-24`   | debian-13 | `make devcontainers/node-24/build`   |

The workflow (`.github/workflows/devcontainers.yml`) is manually triggered and supports building individual images or all at once.

## License

[MIT](LICENSE)
