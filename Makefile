include .env

help:
	@echo '@TODO'

# docker compose

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

# base-devcontainer

devcontainer/setup:
	docker buildx create --use --name multi-arch-builder || true
	docker buildx inspect --bootstrap

devcontainer/clean:
	docker buildx rm multi-arch-builder || true

devcontainer/debian-13/build: devcontainer/setup
	docker buildx build \
		--platform $(DEVCONTAINER_IMAGE_PLATFORMS) \
		--file docker/registry/devcontainers-base/debian-13/Dockerfile \
		--tag $(DEVCONTAINER_BASE_IMAGE_NAME):latest \
		--tag $(DEVCONTAINER_BASE_IMAGE_NAME):$$(date +%Y%m%d) \
		--tag $(DEVCONTAINER_BASE_IMAGE_NAME):debian \
		--tag $(DEVCONTAINER_BASE_IMAGE_NAME):$$(date +%Y%m%d)-debian \
		--tag $(DEVCONTAINER_BASE_IMAGE_NAME):debian-13 \
		--tag $(DEVCONTAINER_BASE_IMAGE_NAME):$$(date +%Y%m%d)-debian-13 \
		--push .

devcontainer/debian-13/build-local:
	docker build \
		--file docker/registry/devcontainers-base/debian-13/Dockerfile \
		--tag $(DEVCONTAINER_BASE_IMAGE_NAME):local \
		.

