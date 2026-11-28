FROM mcr.microsoft.com/devcontainers/base:debian-13

LABEL org.opencontainers.image.source="https://github.com/afonsodemori/infra"
LABEL org.opencontainers.image.licenses=MIT

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
  build-essential \
  shfmt \
  vim \
  tig \
  python3 \
  python3-pip \
  python3-venv \
  python-is-python3 \
  && rm -rf /var/lib/apt/lists/*

COPY docker/registry/devcontainers/debian/debian-13/bashrc.d/ /etc/bashrc.d/
RUN cat >> /etc/bash.bashrc <<'EOF'

for f in /etc/bashrc.d/*.sh; do
  [ -r "$f" ] && . "$f"
done
unset f
EOF

RUN mkdir -p /commandhistory \
  && chown vscode:vscode /commandhistory

USER vscode
WORKDIR /home/vscode

ENV NVM_DIR=/home/vscode/.nvm \
    CLAUDE_CONFIG_DIR=/home/vscode/.claude \
    PATH=/home/vscode/.local/bin:$PATH

RUN mkdir -p "$CLAUDE_CONFIG_DIR"

RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash \
  && . "$NVM_DIR/nvm.sh" \
  && nvm install 24 \
  && nvm alias default 24 \
  # Add nvm to login shells (~/.profile) in addition to interactive shells (~/.bashrc)
  && printf '\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && \\. "$NVM_DIR/nvm.sh"\n' >> ~/.profile \
  && curl -fsSL https://claude.ai/install.sh | bash
