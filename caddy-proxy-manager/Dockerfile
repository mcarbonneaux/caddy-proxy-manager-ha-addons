ARG UPSTREAM_VERSION=latest

FROM caddy:alpine AS caddy-bin

FROM ghcr.io/fuomag9/caddy-proxy-manager-web:${UPSTREAM_VERSION}

# Copy Caddy binary
COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy

# Copy s6-overlay service definitions and init scripts
COPY rootfs/ /

USER root

# Ensure scripts are executable
RUN chmod a+x /etc/s6-overlay/s6-rc.d/init-data/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/init-config/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/caddy/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/cpm/run \
    && chmod a+x /etc/cont-init.d/00-banner.sh

# Create a version file in the image
RUN echo "1.4-ha.11" > /VERSION

# Force removal of upstream entrypoint/cmd
ENTRYPOINT ["/init"]
CMD []
