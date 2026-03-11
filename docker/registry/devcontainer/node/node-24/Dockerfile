FROM ghcr.io/afonsodemori/devcontainer/debian:13

ARG DEBIAN_FRONTEND=noninteractive

RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*
