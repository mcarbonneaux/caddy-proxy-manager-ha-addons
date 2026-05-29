ARG UPSTREAM_VERSION=latest

# Build stage to get Caddy
FROM caddy:alpine AS caddy-bin

# Final stage: Use official Home Assistant base image
# This ensures s6-overlay, bashio, and node are correctly configured
FROM ghcr.io/home-assistant/amd64-base-nodejs:22 AS base-amd64
FROM ghcr.io/home-assistant/aarch64-base-nodejs:22 AS base-aarch64

# Use a build arg to select the correct base image based on architecture
ARG BUILD_ARCH=amd64
FROM base-${BUILD_ARCH}

# Copy Caddy binary
COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy

# Copy application files from upstream image
# We use the upstream image just as a source of files
COPY --from=ghcr.io/fuomag9/caddy-proxy-manager-web:latest /app /app

# Install additional requirements
RUN apk add --no-cache \
    openssl \
    jq \
    curl \
    sqlite

# Copy s6-overlay service definitions and init scripts
COPY rootfs/ /

# Fix permissions
RUN chmod a+x /etc/s6-overlay/s6-rc.d/init-data/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/init-config/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/caddy/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/cpm/run \
    && chmod a+x /etc/cont-init.d/00-banner.sh

# Expose version
RUN echo "1.4-ha.13" > /VERSION

ENTRYPOINT ["/init"]
CMD []
