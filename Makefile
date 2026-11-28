-include .env

COMPOSE = docker compose -f compose.$(SERVER_HOSTNAME).yml

.PHONY: require-env up update-nginx-assets docker/update-images nginx/preflight \
	docker/force-recreate nginx-reload nginx/test-and-reload logs down

require-env:
	@test -n "$(SERVER_HOSTNAME)" || { \
		echo "SERVER_HOSTNAME is not set. Copy .env.<env>.example to .env"; \
		exit 1; \
	}

####################
## docker compose
##########

up: update-nginx-assets
	@$(COMPOSE) up -d --remove-orphans
	@$(MAKE) --no-print-directory nginx/test-and-reload

update-nginx-assets: require-env
	@bash bin/create-server-health-check.sh

docker/update-images: update-nginx-assets
	@$(COMPOSE) --profile ondemand pull
	@$(MAKE) --no-print-directory nginx/preflight
	@$(COMPOSE) up -d --remove-orphans
	@$(MAKE) --no-print-directory nginx/test-and-reload

nginx/preflight: require-env
	@cid=$$($(COMPOSE) run -d --no-deps nginx) || exit 1; \
	sleep 3; \
	state=$$(docker inspect -f '{{.State.Status}} {{.RestartCount}}' $$cid 2>/dev/null); \
	if [ "$$state" != "running 0" ]; then \
		echo "nginx preflight FAILED ($$state); live nginx left untouched:"; \
		docker logs --tail 20 $$cid 2>&1; \
		docker rm -f $$cid >/dev/null 2>&1; \
		exit 1; \
	fi; \
	docker rm -f $$cid >/dev/null; \
	echo "nginx preflight OK."

docker/force-recreate: update-nginx-assets
	@$(COMPOSE) up -d --remove-orphans --force-recreate

nginx-reload: update-nginx-assets nginx/test-and-reload

nginx/test-and-reload: require-env
	@$(COMPOSE) exec nginx nginx -t && \
	$(COMPOSE) exec nginx nginx -s reload && \
	echo "Nginx reloaded."

logs: require-env
	@$(COMPOSE) logs -f

down: require-env
	@$(COMPOSE) down --remove-orphans

####################
## devcontainers
##########

TAG_DATE ?= $$(date +%Y%m%d-%H%M%S)
TAG_COMMIT ?= $$(git rev-parse --short HEAD)

DEBIAN_IMAGE_NAME ?= $(or $(DEVCONTAINERS_DEBIAN_IMAGE_NAME), $(IMAGE_NAME))
GOLANG_IMAGE_NAME ?= $(or $(DEVCONTAINERS_GOLANG_IMAGE_NAME), $(IMAGE_NAME))
NODE_IMAGE_NAME   ?= $(or $(DEVCONTAINERS_NODE_IMAGE_NAME), $(IMAGE_NAME))

devcontainers/debian-13/build:
	docker buildx build . \
		--pull \
		--no-cache \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/debian/debian-13/Dockerfile \
		--tag $(DEBIAN_IMAGE_NAME):13-$(TAG_COMMIT) \
		--tag $(DEBIAN_IMAGE_NAME):13-$(TAG_DATE) \
		--tag $(DEBIAN_IMAGE_NAME):13 \
		--tag $(DEBIAN_IMAGE_NAME):latest \
		--push

devcontainers/debian-13/build-local:
	docker buildx build . \
		--pull \
		--no-cache \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/debian/debian-13/Dockerfile \
		--tag $(DEVCONTAINERS_DEBIAN_IMAGE_NAME):local

devcontainers/go-1-27/build:
	docker buildx build . \
		--pull \
		--no-cache \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/golang/go-1-27/Dockerfile \
		--tag $(GOLANG_IMAGE_NAME):1.27-$(TAG_COMMIT) \
		--tag $(GOLANG_IMAGE_NAME):1.27-$(TAG_DATE) \
		--tag $(GOLANG_IMAGE_NAME):1.27 \
		--tag $(GOLANG_IMAGE_NAME):latest \
		--push

devcontainers/go-1-27/build-local:
	docker buildx build . \
		--pull \
		--no-cache \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/golang/go-1-27/Dockerfile \
		--tag $(DEVCONTAINERS_GOLANG_IMAGE_NAME):local

devcontainers/node-24/build:
	docker buildx build . \
		--pull \
		--no-cache \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/node/node-24/Dockerfile \
		--tag $(NODE_IMAGE_NAME):24-$(TAG_COMMIT) \
		--tag $(NODE_IMAGE_NAME):24-$(TAG_DATE) \
		--tag $(NODE_IMAGE_NAME):24 \
		--tag $(NODE_IMAGE_NAME):latest \
		--push

devcontainers/node-24/build-local:
	docker buildx build . \
		--pull \
		--no-cache \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers/node/node-24/Dockerfile \
		--tag $(DEVCONTAINERS_NODE_IMAGE_NAME):local

registry/php-85/build-local:
	docker buildx build . \
		--pull \
		--no-cache \
		--platform $(DEVCONTAINERS_IMAGE_PLATFORMS) \
		--file docker/registry/php/php-85/Dockerfile \
		--tag $(DEVCONTAINERS_PHP_IMAGE_NAME):local
