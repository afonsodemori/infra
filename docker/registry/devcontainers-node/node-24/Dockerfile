FROM ghcr.io/afonsodemori/devcontainers/base:debian-13

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get purge -y npm \
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
