# infra

Infrastructure-as-code for managing a multi-service production environment using Docker Compose and Nginx as a reverse proxy. Supports multiple deployment targets with shared service definitions.

Service status at: <https://status.afonso.dev>

## Environments

| Compose file              | Target                  | Services                                           |
| ------------------------- | ----------------------- | -------------------------------------------------- |
| `compose.oci-prod.yml`    | Oracle Cloud Production | afonsodev-production, jrbaena, meteosaucana, psono |
| `compose.oci-staging.yml` | Oracle Cloud Staging    | afonsodev-preview, pgadmin, snippetbox             |
| `compose.oci-labs.yml`    | Oracle Cloud Labs       | uptime-kuma, vpn                                   |

Every environment also runs nginx, PostgreSQL, Alloy and (on demand) Certbot.

## Setup

1. Copy the example env file for your target environment:

   ```bash
   cp .env.oci-prod.example .env       # or .env.oci-staging.example, etc.
   ```

2. Fill in the required values in `.env`. At minimum:
   - `SERVER_HOSTNAME` — must match one of the environment names above (e.g. `oci-prod`)
   - `INFRA_DIR`, `DATA_DIR` — host paths for config and data
   - `NGINX_VERSION` — nginx image tag
   - `DATABASE_POSTGRES_PASSWORD`, `DATABASE_POSTGRES_VERSION`

3. Create required data directories:

   ```bash
   bin/install-data-dirs.sh
   ```

4. Install the crontab for this server (`config/crontab.$SERVER_HOSTNAME`):

   ```bash
   bin/crontab-install.sh
   ```

5. Symlink the vhosts this server should serve from `docker/nginx/sites-available/` into `docker/nginx/sites-enabled/`.

## Common Commands

All commands require `SERVER_HOSTNAME` to be set in `.env`.

```bash
make up                       # Generate nginx assets, then start all services
make down                     # Stop all services
make logs                     # Tail logs for all services
make nginx-reload             # Generate nginx assets, test config, and reload
make docker/update-images     # Pull latest images and restart
make docker/force-recreate    # Force recreate all containers
make update-nginx-assets      # Generate health.json and 404.html for nginx
```

## Architecture

### Services

Individual service definitions live in `docker/compose/`:

| File                                         | Description                                     |
| -------------------------------------------- | ----------------------------------------------- |
| `compose.database.yml`                       | PostgreSQL (localhost:5432 only)                |
| `compose.jrbaena-production.yml`             | jrbaena.com web app                             |
| `compose.meteosaucana-production.yml`        | meteosaucana.com web app                        |
| `compose.mycrew-{production,preview}.yml`    | MyCrew API (not currently included anywhere)    |
| `compose.afonsodev-{production,preview}.yml` | afonso.dev web + API                            |
| `compose.snippetbox.yml`                     | Snippetbox app + temporary MySQL (localhost:3306) |
| `compose.psono.yml`                          | Psono password manager                          |
| `compose.vpn.yml`                            | WireGuard Easy VPN                              |
| `compose.pgadmin.yml`                        | pgAdmin database UI                             |
| `compose.uptime-kuma.yml`                    | Uptime Kuma monitoring                          |
| `compose.alloy.yml`                          | Grafana Alloy log collector                     |
| `compose.certbot.yml`                        | Certbot SSL certificates (`ondemand` profile)   |

To add a new service: create a file in `docker/compose/`, then add an `include:` entry to the relevant top-level compose file(s).

### Nginx Reverse Proxy

`docker/nginx/` layout:

```
nginx.conf                  Main nginx config
sites-available/            One .conf per vhost
sites-enabled/              Symlinks to enabled vhosts (mounted as conf.d, git-ignored, per server)
snippets/                   Reusable includes (security, proxy, ssl-common)
html/404.html               404 page template
```

`make update-nginx-assets` (run automatically by `up`, `nginx-reload`, `docker/update-images` and `docker/force-recreate`) renders the 404 page and generates `health.json` into `$DATA_DIR/nginx/dist/`.

To add a new vhost: create a config in `sites-available/`, symlink it in `sites-enabled/` on the server, then run `make nginx-reload`.

### SSL Certificates

Managed by Certbot via Cloudflare DNS-01 challenge. Cert data is stored in `$DATA_DIR/letsencrypt/data` (mounted read-only into nginx). Renewal runs via cron on a per-server schedule defined in `config/crontab.$SERVER_HOSTNAME`.

### Backups

`bin/postgres-backup.sh` runs from each server's crontab and writes backups to `$PG_BACKUP_BACKUP_DIR/<timestamp>`. It keeps them for `$PG_BACKUP_RETENTION_DAYS` days. Restore with `bin/postgres-restore.sh <timestamp>`.

### Observability

- **Grafana Alloy** — ships container logs to a Grafana Cloud Loki endpoint
- **Uptime Kuma** — service uptime monitoring dashboard
- **Health checks** — `/health.json` served by nginx per server

## Utility Scripts

```bash
bin/postgres-backup.sh               # Back up PostgreSQL
bin/postgres-restore.sh <timestamp>  # Restore a PostgreSQL backup
bin/certbot.sh <cmd>                 # Run certbot (e.g. renew), then reload nginx
bin/create-server-health-check.sh    # Generate nginx health.json and 404.html
bin/crontab-install.sh               # Install crontab from config/crontab.$SERVER_HOSTNAME
bin/install-data-dirs.sh             # Create required host data directories
bin/install-packages.sh              # Install required host packages
```

## Devcontainer Images

Custom base images are defined in `docker/registry/devcontainers/` and published to `ghcr.io/afonsodemori/devcontainers/` via GitHub Actions.

| Image       | Base      | Make target                          |
| ----------- | --------- | ------------------------------------ |
| `debian-13` | Debian 13 | `make devcontainers/debian-13/build` |
| `go-1-27`   | debian-13 | `make devcontainers/go-1-27/build`   |
| `node-24`   | debian-13 | `make devcontainers/node-24/build`   |

The workflow (`.github/workflows/devcontainers.yml`) is manually triggered and supports building individual images or all at once.

See [`docker/registry/devcontainers/README.md`](docker/registry/devcontainers/README.md) for usage, including the optional volumes for persisting shell history and Claude Code config.

## License

[MIT](LICENSE)
