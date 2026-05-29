ARG BUILD_ARCH=amd64
ARG UPSTREAM_VERSION=latest

# Build stage to get Caddy
FROM caddy:alpine AS caddy-bin

# Final stage: Use official Home Assistant base image
FROM ghcr.io/home-assistant/${BUILD_ARCH}-base-nodejs:22

# Re-declare BUILD_ARCH so it's available after FROM
ARG BUILD_ARCH

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
RUN echo "1.4-ha.14" > /VERSION

ENTRYPOINT ["/init"]
CMD []
