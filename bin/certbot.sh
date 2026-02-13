#!/usr/bin/env bash
set -e

cmd="$1"

docker compose run --rm -i certbot "$@"

case "$cmd" in
  new|renew|revoke|delete)
    make nginx-reload
    ;;
esac
