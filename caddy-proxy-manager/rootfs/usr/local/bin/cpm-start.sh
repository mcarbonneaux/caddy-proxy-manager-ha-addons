#!/bin/bash
set -a
# shellcheck source=/data/config/addon.env
[ -f /data/config/addon.env ] && . /data/config/addon.env
set +a
exec bun /app/server.js
