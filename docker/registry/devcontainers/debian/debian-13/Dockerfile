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
  vim \
  curl \
  git \
  tig \
  && apt-get autoremove -y && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

USER vscode

WORKDIR /home/vscode

ENV NVM_DIR=/home/vscode/.nvm

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
  && . $NVM_DIR/nvm.sh \
  && nvm install 22 \
  && nvm alias default 22 \
  # Add nvm and node to login shells (~/.profile) in addition to interactive shells (~/.bashrc)
  && printf '\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n' >> ~/.profile \
  && curl -fsSL https://claude.ai/install.sh | bash \
  && curl -fsSL https://fns-cli.afonso.dev/install.sh | bash
