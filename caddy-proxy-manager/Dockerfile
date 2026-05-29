# Use community base image like Franck (Nginx Proxy Manager)
ARG BUILD_ARCH=amd64
FROM ghcr.io/hassio-addons/base:17.2.1

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Build stage to get Caddy
FROM caddy:alpine AS caddy-bin

# Return to main build
FROM ghcr.io/hassio-addons/base:17.2.1

# Re-declare BUILD_ARCH
ARG BUILD_ARCH

# Copy Caddy binary
COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy

# Copy application files from upstream image
COPY --from=ghcr.io/fuomag9/caddy-proxy-manager-web:latest /app /app

# Install NodeJS and additional requirements
RUN apk add --no-cache \
    nodejs \
    npm \
    openssl \
    jq \
    curl \
    sqlite

# Copy init scripts and services
COPY rootfs/ /

# Ensure scripts are executable
RUN chmod -R +x /etc/cont-init.d/ \
    && chmod -R +x /etc/services.d/

# Expose version
RUN echo "1.4-ha.18" > /VERSION

# S6 configuration (Community style)
ENV S6_KEEP_ENV=1 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_VERBOSITY=2

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
