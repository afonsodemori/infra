FROM ghcr.io/afonsodemori/devcontainers/debian:13

LABEL org.opencontainers.image.source="https://github.com/afonsodemori/infra"
LABEL org.opencontainers.image.licenses=MIT

USER vscode

RUN . $NVM_DIR/nvm.sh \
  && nvm install 24 \
  && nvm alias default 24 \
  && nvm uninstall 22
