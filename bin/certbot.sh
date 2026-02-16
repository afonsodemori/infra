#!/usr/bin/env bash
set -e

cmd="$1"

docker compose run --rm -i certbot "$@"

case "$cmd" in
  new|renew)
    docker compose run --rm -T --entrypoint=/bin/sh certbot -c 'chown -R 65532:65532 /etc/letsencrypt'
    make nginx-reload
    ;;
  new|renew|revoke|delete)
    make nginx-reload
    ;;
esac
