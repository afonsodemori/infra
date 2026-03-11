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
## devcontainer
##########

TAG_DATE ?= $$(date +%Y%m%d-%H%M%S)
TAG_COMMIT ?= $$(git rev-parse --short HEAD)

devcontainer/debian-13/build:
	docker buildx build \
		--platform $(DEVCONTAINER_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainer/debian/debian-13/Dockerfile \
		--tag $(DEVCONTAINER_DEBIAN_IMAGE_NAME):13 \
		--tag $(DEVCONTAINER_DEBIAN_IMAGE_NAME):13-$(TAG_DATE) \
		--tag $(DEVCONTAINER_DEBIAN_IMAGE_NAME):13-$(TAG_COMMIT) \
		--push .

devcontainer/debian-13/build-local:
	docker build \
		--file docker/registry/devcontainer/debian/debian-13/Dockerfile \
		--tag $(DEVCONTAINER_DEBIAN_IMAGE_NAME):13 \
		.

devcontainer/go-1.26/build:
	docker buildx build \
		--platform $(DEVCONTAINER_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainer/golang/go-1.26/Dockerfile \
		--tag $(DEVCONTAINER_GOLANG_IMAGE_NAME):1.26 \
		--tag $(DEVCONTAINER_GOLANG_IMAGE_NAME):1.26-$(TAG_DATE) \
		--tag $(DEVCONTAINER_GOLANG_IMAGE_NAME):1.26-$(TAG_COMMIT) \
		--push .

devcontainer/go-1.26/build-local:
	docker build \
		--file docker/registry/devcontainer/golang/go-1.26/Dockerfile \
		--tag $(DEVCONTAINER_GOLANG_IMAGE_NAME):1.26 \
		.

devcontainer/node-24/build:
	docker buildx build \
		--platform $(DEVCONTAINER_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainer/node/node-24/Dockerfile \
		--tag $(DEVCONTAINER_NODE_IMAGE_NAME):24 \
		--tag $(DEVCONTAINER_NODE_IMAGE_NAME):24-$(TAG_DATE) \
		--tag $(DEVCONTAINER_NODE_IMAGE_NAME):24-$(TAG_COMMIT) \
		--push .

devcontainer/node-24/build-local:
	docker build \
		--file docker/registry/devcontainer/node/node-24/Dockerfile \
		--tag $(DEVCONTAINER_NODE_IMAGE_NAME):24 \
		.
