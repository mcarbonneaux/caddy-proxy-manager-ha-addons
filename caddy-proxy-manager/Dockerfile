ARG UPSTREAM_VERSION=latest

FROM caddy:alpine AS caddy-bin

FROM ghcr.io/fuomag9/caddy-proxy-manager-web:${UPSTREAM_VERSION}

# Copy Caddy binary
COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy

# Copy s6-overlay service definitions and init scripts
COPY rootfs/ /

# Ensure scripts are executable
RUN chmod a+x /etc/s6-overlay/s6-rc.d/init-data/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/init-config/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/caddy/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/cpm/run

CMD ["/init"]
