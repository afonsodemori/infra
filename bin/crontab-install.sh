#!/bin/bash

set -e
source .env

home_dir="${INFRA_DIR:?}"
hostname="${SERVER_HOSTNAME:?}"

crontab "$home_dir/config/crontab.$hostname"

echo "Installed crontab:"
crontab -l

echo "Done."
