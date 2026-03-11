FROM ghcr.io/afonsodemori/devcontainers/base:debian-13

RUN curl -fsSL https://go.dev/dl/go1.26.1.linux-amd64.tar.gz | tar -C /usr/local -xzf -

ENV GOROOT=/usr/local/go
ENV GOPATH=/home/vscode/go
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"

RUN mkdir -p /home/vscode/go && chown -R vscode:vscode /home/vscode/go
