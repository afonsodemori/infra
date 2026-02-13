#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source .env

home_dir="${INFRA_DIR:?}"

crontab "$home_dir/config/crontab"

echo "Installed crontab:"
crontab -l

echo "Done."
