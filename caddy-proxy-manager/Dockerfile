ARG UPSTREAM_VERSION=latest

FROM caddy:alpine AS caddy-bin

FROM ghcr.io/fuomag9/caddy-proxy-manager-web:${UPSTREAM_VERSION}

# Copy Caddy binary
COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy

# Install bash and openssl (required for bashio and secret generation)
# The upstream image might be based on Alpine
RUN apk add --no-cache bash openssl jq curl

# Copy s6-overlay service definitions and init scripts
COPY rootfs/ /

USER root

# In case the upstream has an entrypoint script that we need to disable
RUN if [ -f /usr/local/bin/docker-entrypoint.sh ]; then mv /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh.bak; fi \
    && if [ -f /entrypoint.sh ]; then mv /entrypoint.sh /entrypoint.sh.bak; fi

# Ensure scripts are executable
RUN chmod a+x /etc/s6-overlay/s6-rc.d/init-data/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/init-config/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/caddy/run \
    && chmod a+x /etc/s6-overlay/s6-rc.d/cpm/run \
    && chmod a+x /etc/cont-init.d/00-banner.sh

# Create a version file in the image
RUN echo "1.4-ha.12" > /VERSION

# Force S6 to be the entrypoint and ignore any inherited CMD
ENTRYPOINT ["/init"]
CMD []
