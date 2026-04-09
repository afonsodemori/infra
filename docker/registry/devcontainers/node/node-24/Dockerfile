FROM ghcr.io/afonsodemori/devcontainers/debian:13

LABEL org.opencontainers.image.source="https://github.com/afonsodemori/infra"
LABEL org.opencontainers.image.licenses=MIT

USER root

ARG DEBIAN_FRONTEND=noninteractive
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
  && apt-get install -y nodejs \
  && apt-get autoremove -y && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

USER vscode
