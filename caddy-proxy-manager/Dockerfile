ARG BUILD_ARCH=amd64
ARG BUILD_VERSION=unknown

# Caddy binary
FROM caddy:alpine AS caddy-bin

# CPM web app
FROM ghcr.io/fuomag9/caddy-proxy-manager-web:latest AS cpm-app

# Build go-supervisord from source (ensures correct arch)
FROM golang:1.24-alpine AS supervisord-bin
RUN apk add --no-cache git \
    && git clone https://github.com/ochinchina/supervisord.git /src/supervisord \
    && cd /src/supervisord \
    && go build -o /usr/local/bin/supervisord .

# Final image — based on oven/bun:alpine which ships a musl-compatible Bun binary
FROM oven/bun:1-alpine

ARG BUILD_ARCH
ARG BUILD_VERSION

RUN apk add --no-cache \
    bash \
    jq \
    openssl \
    sqlite

COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy
COPY --from=cpm-app /app /app
COPY --from=supervisord-bin /usr/local/bin/supervisord /usr/bin/supervisord

COPY rootfs /

RUN chmod +x /usr/local/bin/init-config.sh \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/caddy-start.sh \
    && chmod +x /usr/local/bin/cpm-start.sh \
    && mkdir -p /data/db /data/certs /data/config /data/logs

RUN echo "${BUILD_VERSION}" > /VERSION

ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY

LABEL \
    io.hass.name="Caddy Proxy Manager" \
    io.hass.description="Caddy reverse proxy managed by caddy-proxy-manager web UI" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version="${BUILD_VERSION}"

CMD ["/usr/local/bin/entrypoint.sh"]
