# Use community base image like Franck (Nginx Proxy Manager)
ARG BUILD_ARCH=amd64
FROM ghcr.io/hassio-addons/base:18.2.0

# Build stage to get Caddy
FROM caddy:alpine AS caddy-bin

# Final stage
FROM ghcr.io/hassio-addons/base:18.2.0

# Re-declare BUILD_ARCH and BUILD_VERSION
ARG BUILD_ARCH
ARG BUILD_VERSION=unknown

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy Caddy binary
COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy

# Copy application files from upstream image
COPY --from=ghcr.io/fuomag9/caddy-proxy-manager-web:latest /app /app

# Copy rootfs
COPY rootfs /

# Install NodeJS and additional requirements
RUN apk add --no-cache \
    nodejs \
    npm \
    sqlite

# Fix line endings (Windows CRLF -> LF), set up s6-rc.d types, dependencies, and contents
RUN sed -i 's/\r//' /etc/s6-overlay/s6-rc.d/init-data/run \
    && sed -i 's/\r//' /etc/s6-overlay/s6-rc.d/init-config/run \
    && sed -i 's/\r//' /etc/s6-overlay/s6-rc.d/caddy/run \
    && sed -i 's/\r//' /etc/s6-overlay/s6-rc.d/cpm/run \
    && mkdir -p /etc/s6-overlay/s6-rc.d/init-data/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/init-config/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/caddy/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/cpm/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
    && printf "oneshot" > /etc/s6-overlay/s6-rc.d/init-data/type \
    && printf "oneshot" > /etc/s6-overlay/s6-rc.d/init-config/type \
    && printf "longrun" > /etc/s6-overlay/s6-rc.d/caddy/type \
    && printf "longrun" > /etc/s6-overlay/s6-rc.d/cpm/type \
    && touch /etc/s6-overlay/s6-rc.d/init-data/up \
    && touch /etc/s6-overlay/s6-rc.d/init-config/up \
    && touch /etc/s6-overlay/s6-rc.d/caddy/up \
    && touch /etc/s6-overlay/s6-rc.d/cpm/up \
    && touch /etc/s6-overlay/s6-rc.d/init-config/dependencies.d/init-data \
    && touch /etc/s6-overlay/s6-rc.d/caddy/dependencies.d/init-config \
    && touch /etc/s6-overlay/s6-rc.d/caddy/dependencies.d/init-data \
    && touch /etc/s6-overlay/s6-rc.d/cpm/dependencies.d/caddy \
    && touch /etc/s6-overlay/s6-rc.d/cpm/dependencies.d/init-config \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/init-data \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/init-config \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/caddy \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/cpm \
    && chmod -R +x /etc/s6-overlay/s6-rc.d/

# Expose version
RUN echo "${BUILD_VERSION}" > /VERSION

# Build arguments for Labels
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="Caddy Proxy Manager" \
    io.hass.description="Caddy reverse proxy managed by caddy-proxy-manager web UI" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}"
