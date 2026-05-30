ARG BUILD_ARCH=amd64
ARG BUILD_VERSION=unknown

# Caddy binary
FROM caddy:alpine AS caddy-bin

# CPM web app
FROM ghcr.io/fuomag9/caddy-proxy-manager-web:latest AS cpm-app

# go-supervisord
FROM ochinchina/supervisord:latest AS supervisord-bin

# Final image
FROM alpine:3.19

ARG BUILD_ARCH
ARG BUILD_VERSION

RUN apk add --no-cache \
    bash \
    jq \
    openssl \
    nodejs \
    sqlite

COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy
COPY --from=cpm-app /app /app
COPY --from=supervisord-bin /usr/local/bin/supervisord /usr/bin/supervisord

COPY rootfs /

RUN chmod +x /usr/local/bin/init-config.sh \
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

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
