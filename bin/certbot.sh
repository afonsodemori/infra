#!/bin/bash

set -e
source .env

cmd="$1"
hostname="${SERVER_HOSTNAME:?}"
compose="docker compose -f compose.$hostname.yml"

$compose run --rm -i certbot "$@"

case "$cmd" in
  new|renew)
    # nginx user is 65532
    $compose run --rm -T --entrypoint=/bin/sh certbot -c 'chown -R 65532:65532 /etc/letsencrypt'
    make nginx-reload
    ;;
  new|renew|revoke|delete)
    make nginx-reload
    ;;
esac
