include .env

help:
	@echo '@TODO'

# docker images

registry-login:
	@docker login registry.gitlab.com

.PHONY: docker/letsencrypt
docker/letsencrypt: DOCKER_IMAGE = registry.gitlab.com/afonsodemori/infra/letsencrypt
docker/letsencrypt: TODAY = $(shell date +%F)
docker/letsencrypt:
	@docker build \
		--platform linux/amd64 \
		--file docker/letsencrypt/Dockerfile . \
		--tag $(DOCKER_IMAGE):$(TODAY)
		--tag $(DOCKER_IMAGE):latest \
	@docker push $(DOCKER_IMAGE):$(TODAY)
	@docker push $(DOCKER_IMAGE):latest

# docker compose

pull:
	@docker compose pull

up:
	@docker compose up -d

logs:
	@docker compose logs -f

down:
	@docker compose down --remove-orphans

# import from remote

copy/all: copy/letsencrypt copy/mariadb copy/sonar

# internals

.builder-create:
	@docker buildx use multi_arch 2>/dev/null || docker buildx create --name multi_arch --use

.builder-delete:
	@docker builder rm multi_arch
