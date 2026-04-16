FROM ghcr.io/afonsodemori/devcontainers/debian:13

LABEL org.opencontainers.image.source="https://github.com/afonsodemori/infra"
LABEL org.opencontainers.image.licenses=MIT

USER root

ARG DEBIAN_FRONTEND=noninteractive
RUN echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' | tee /etc/apt/sources.list.d/goreleaser.list \
  && apt-get update \
  && apt-get install -y goreleaser \
  && apt-get autoremove -y && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* \
  && curl -fsSL "https://go.dev/dl/go1.26.1.linux-$(dpkg --print-architecture).tar.gz" | tar -C /usr/local -xzf -

USER vscode
ENV GOROOT=/usr/local/go
ENV GOPATH=/home/vscode/go
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"
