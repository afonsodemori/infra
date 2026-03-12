-include .env

help:
	@echo '@TODO'

####################
## docker compose
##########

docker/update-images:
	@docker compose pull
	@docker compose up -d --remove-orphans

docker/force-recreate:
	@docker compose up -d --remove-orphans --force-recreate

nginx-reload:
	@docker compose exec nginx nginx -t && \
	docker compose exec nginx nginx -s reload && \
	echo "Nginx reloaded."

up:
	@docker compose up -d --remove-orphans

logs:
	@docker compose logs -f

down:
	@docker compose down --remove-orphans

####################
## devcontainers
##########

TAG_DATE ?= $$(date +%Y%m%d-%H%M%S)
TAG_COMMIT ?= $$(git rev-parse --short HEAD)

DEBIAN_IMAGE_NAME ?= $(or $(DEVCONTAINERS_DEBIAN_IMAGE_NAME), $(IMAGE_NAME))
GOLANG_IMAGE_NAME ?= $(or $(DEVCONTAINERS_GOLANG_IMAGE_NAME), $(IMAGE_NAME))
NODE_IMAGE_NAME   ?= $(or $(DEVCONTAINERS_NODE_IMAGE_NAME), $(IMAGE_NAME))

devcontainers/debian-13/build:
	docker buildx build \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/debian/debian-13/Dockerfile \
		--tag $(DEBIAN_IMAGE_NAME):13-$(TAG_COMMIT) \
		--tag $(DEBIAN_IMAGE_NAME):13-$(TAG_DATE) \
		--tag $(DEBIAN_IMAGE_NAME):13 \
		--tag $(DEBIAN_IMAGE_NAME):latest \
		--push .

devcontainers/debian-13/build-local:
	docker buildx build \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/debian/debian-13/Dockerfile \
		--tag $(DEVCONTAINERS_DEBIAN_IMAGE_NAME):13-$(TAG_DATE) \
		--tag $(DEVCONTAINERS_DEBIAN_IMAGE_NAME):13 \
		--tag $(DEVCONTAINERS_DEBIAN_IMAGE_NAME):latest \
		.

devcontainers/go-1.26/build:
	docker buildx build \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/golang/go-1.26/Dockerfile \
		--tag $(GOLANG_IMAGE_NAME):1.26-$(TAG_COMMIT) \
		--tag $(GOLANG_IMAGE_NAME):1.26-$(TAG_DATE) \
		--tag $(GOLANG_IMAGE_NAME):1.26 \
		--tag $(GOLANG_IMAGE_NAME):latest \
		--push .

devcontainers/go-1.26/build-local:
	docker buildx build \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/golang/go-1.26/Dockerfile \
		--tag $(DEVCONTAINERS_GOLANG_IMAGE_NAME):1.26-$(TAG_DATE) \
		--tag $(DEVCONTAINERS_GOLANG_IMAGE_NAME):1.26 \
		--tag $(DEVCONTAINERS_GOLANG_IMAGE_NAME):latest \
		.

devcontainers/node-24/build:
	docker buildx build \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/node/node-24/Dockerfile \
		--tag $(NODE_IMAGE_NAME):24-$(TAG_COMMIT) \
		--tag $(NODE_IMAGE_NAME):24-$(TAG_DATE) \
		--tag $(NODE_IMAGE_NAME):24 \
		--tag $(NODE_IMAGE_NAME):latest \
		--push .

devcontainers/node-24/build-local:
	docker buildx build \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/node/node-24/Dockerfile \
		--tag $(DEVCONTAINERS_NODE_IMAGE_NAME):24-$(TAG_DATE) \
		--tag $(DEVCONTAINERS_NODE_IMAGE_NAME):24 \
		--tag $(DEVCONTAINERS_NODE_IMAGE_NAME):latest \
		.
