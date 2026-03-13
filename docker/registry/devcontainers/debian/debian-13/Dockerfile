FROM mcr.microsoft.com/devcontainers/base:debian-13

LABEL org.opencontainers.image.source="https://github.com/afonsodemori/infra"
LABEL org.opencontainers.image.licenses=MIT

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
    && mkdir -p /home/vscode/.npm /home/vscode/.npm-global \
    && npm install -g @google/gemini-cli \
    && curl -fsSL https://fns-cli.afonso.dev/install.sh | sh \
    && chown -R vscode:vscode /home/vscode/.npm-global /home/vscode/.npm
