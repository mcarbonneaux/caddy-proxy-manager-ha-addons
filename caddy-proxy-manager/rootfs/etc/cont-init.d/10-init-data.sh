#!/usr/bin/with-contenv bashio
bashio::log.info "Initializing /data directories..."
mkdir -p /data/db /data/certs /data/config /data/logs
bashio::log.info "Done."
