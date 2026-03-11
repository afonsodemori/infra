FROM mcr.microsoft.com/devcontainers/base:debian-13

ARG DEBIAN_FRONTEND=noninteractive

ENV NPM_CONFIG_PREFIX=/home/vscode/.npm-global
ENV PATH=$NPM_CONFIG_PREFIX/bin:$PATH

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    shfmt \
    nodejs \
    vim \
    curl \
    git \
    tig \
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @google/gemini-cli \
    && curl -fsSL https://fns-cli.afonso.dev/install.sh | sh
