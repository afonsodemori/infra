FROM ghcr.io/afonsodemori/devcontainer/debian:13

ARG DEBIAN_FRONTEND=noninteractive

RUN echo 'deb [trusted=yes] https://repo.goreleaser.com/apt/ /' | sudo tee /etc/apt/sources.list.d/goreleaser.list \
    && apt-get install -y goreleaser \
    && apt-get autoremove -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://go.dev/dl/go1.26.1.linux-amd64.tar.gz | tar -C /usr/local -xzf -

ENV GOROOT=/usr/local/go
ENV GOPATH=/home/vscode/go
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"

RUN mkdir -p /home/vscode/go && chown -R vscode:vscode /home/vscode/go
