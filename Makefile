include .env

help:
	@echo '@TODO'

# docker images

registry-login:
	@docker login registry.gitlab.com

docker/letsencrypt: registry-login .builder-create
	@docker buildx build \
		--platform linux/amd64,linux/arm64 \
		--file docker/letsencrypt/Dockerfile . \
		--tag registry.gitlab.com/afonsodemori/infra/letsencrypt:latest \
		--push
	@docker pull registry.gitlab.com/afonsodemori/infra/letsencrypt:latest

# docker compose

pull:
	@docker compose pull

up:
	@docker compose up -d

down:
	@docker compose kill
	@docker compose down

# import from remote

copy/all: copy/letsencrypt copy/mariadb copy/mysql copy/sonar

copy/letsencrypt:
	@./bin/copy-data-from-server letsencrypt

copy/mariadb:
	@./bin/copy-data-from-server mariadb

copy/mysql:
	@./bin/copy-data-from-server mysql

copy/sonar:
	@./bin/copy-data-from-server sonar

# internals

.builder-create:
	@docker buildx use multi_arch 2>/dev/null || docker buildx create --name multi_arch --use

.builder-delete:
	@docker builder rm multi_arch
