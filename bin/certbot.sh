#!/usr/bin/env bash
set -e

[ ${SERVER_HOSTNAME:?} == "ion-vps" ] || { echo "SERVER_HOSTNAME is not set to ion-vps, exiting."; exit 1; }

cmd="$1"

docker compose -f compose.ion-vps.yml run --rm -i certbot "$@"

case "$cmd" in
  new|renew)
    docker compose -f compose.ion-vps.yml run --rm -T --entrypoint=/bin/sh certbot -c 'chown -R 65532:65532 /etc/letsencrypt'
    make nginx-reload
    ;;
  new|renew|revoke|delete)
    make nginx-reload
    ;;
esac
