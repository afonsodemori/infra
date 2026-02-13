#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

source .env

data_dir="${DATA_DIR:?}"

echo "Creating directories:"
mkdir -pv "$data_dir/cron"

echo "Done."
