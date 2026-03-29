#!/bin/bash

source .env

cat > /tmp/health.json <<EOF
{
  "status": "up",
  "service": "${SERVER_HOSTNAME:?}",
  "build_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
