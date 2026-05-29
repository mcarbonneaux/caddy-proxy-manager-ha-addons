#!/usr/bin/env bashio
# ==============================================================================
# Home Assistant Add-on: Caddy Proxy Manager
# Initializing /data directories
# ==============================================================================
bashio::log.info "Initializing /data directories..."
mkdir -p /data/db /data/certs /data/config /data/logs
bashio::log.info "Done."
