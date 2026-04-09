FROM mcr.microsoft.com/devcontainers/base:debian-13

LABEL org.opencontainers.image.source="https://github.com/afonsodemori/infra"
LABEL org.opencontainers.image.licenses=MIT

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  gnupg \
  lsb-release \
  build-essential \
  shfmt \
  nodejs \
  npm \
  vim \
  curl \
  git \
  tig \
  && apt-get autoremove -y && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

USER vscode
RUN npm config set prefix ~/.npm-global \
  && curl -fsSL https://claude.ai/install.sh | bash \
  && curl -fsSL https://fns-cli.afonso.dev/install.sh | bash
