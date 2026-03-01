# infra

This repository manages the infrastructure for several personal and production environments using Docker Compose and Nginx as a central reverse proxy. It includes automated setup scripts, backup procedures, and monitoring tools.

## Project Overview

- **Architecture:** Centralized Nginx reverse proxy routing traffic to various application containers.
- **Technologies:** Docker, Docker Compose, Nginx, Certbot (Cloudflare DNS challenge), PostgreSQL, Prometheus/Grafana (Monitoring), and WireGuard.
- **Environments:** Manages multiple environments including `production`, `staging`, `test`, and `sandbox` for different projects (afonsodev, mycrew, ephemeral, etc.).

## Key Directories

- `bin/`: Shell scripts for system installation (`install-packages.sh`), data directory setup (`install-data-dirs.sh`), crontab installation (`install-crontab.sh`), and PostgreSQL backups (`backup-pg-export.sh`).
- `docker/compose/`: Individual Docker Compose files for each service and environment, included in the main `compose.yml`.
- `docker/nginx/`: Nginx configuration including site-specific `conf.d` files and reusable snippets.
- `config/`: System configuration files like `crontab`, `.vimrc`, and shell `profile`.

## Setup and Management

### Prerequisites

- Debian-based Linux system.
- Environment variables configured in `.env` (based on `.env.example`).

### Installation

1.  **Install System Packages:** Run `sudo ./bin/install-packages.sh` to install Docker, Make, and other dependencies.
2.  **Setup Data Directories:** Run `./bin/install-data-dirs.sh` to create necessary persistent storage paths.
3.  **Configure Environment:** Copy `.env.example` to `.env` and fill in the required secrets and versions.
4.  **Install Crontab:** Run `./bin/install-crontab.sh` to set up scheduled tasks (backups, etc.).

### Common Commands (Makefile)

- `make up`: Start all services in the background.
- `make down`: Stop and remove all containers.
- `make logs`: Follow logs from all containers.
- `make nginx-reload`: Test Nginx configuration and reload the service.
- `make docker/update-images`: Pull latest images and recreate containers.
- `make docker/force-recreate`: Force recreation of all containers.

## Development Conventions

- **Surgical Updates:** When modifying Nginx configurations, always run `make nginx-reload` to verify the syntax.
- **Service Isolation:** Each application or tool has its own compose file in `docker/compose/` and is included in the root `compose.yml`.
- **Persistent Data:** All persistent data should be mapped to the directory specified by `DATA_DIR` in the `.env` file.
- **Backups:** PostgreSQL backups are managed via `bin/backup-pg-export.sh` and should be scheduled via crontab.
