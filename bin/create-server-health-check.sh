#!/bin/bash

source .env

data_dir="${DATA_DIR:?}"
infra_dir="${INFRA_DIR:?}"
server_hostname="${SERVER_HOSTNAME:?}"

docker run --rm \
  -v "${data_dir}/nginx:/target" \
  -v "${infra_dir}/docker/nginx/html:/source:ro" \
  -e SERVER_HOSTNAME="${server_hostname}" \
  alpine:latest sh -c '
    mkdir -p /target/dist

    echo "{\"status\": \"up\", \"service\": \"${SERVER_HOSTNAME}\", \"build_time\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"}" > /target/dist/health.json

    sed "s/{HOSTNAME}/${SERVER_HOSTNAME}/g" /source/404.html > /target/dist/404.html
  '
