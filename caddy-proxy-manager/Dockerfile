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

# Ensure s6-rc.d files are correctly set up (fixing potential missing files or line endings)
RUN printf "oneshot" > /etc/s6-overlay/s6-rc.d/init-config/type \
    && printf "longrun" > /etc/s6-overlay/s6-rc.d/caddy/type \
    && printf "oneshot" > /etc/s6-overlay/s6-rc.d/init-data/type \
    && printf "longrun" > /etc/s6-overlay/s6-rc.d/cpm/type \
    && touch /etc/s6-overlay/s6-rc.d/init-config/up \
    && touch /etc/s6-overlay/s6-rc.d/caddy/up \
    && touch /etc/s6-overlay/s6-rc.d/init-data/up \
    && touch /etc/s6-overlay/s6-rc.d/cpm/up \
    && for service in init-config init-data caddy cpm; do \
         touch /etc/s6-overlay/s6-rc.d/user/contents.d/$service; \
       done \
    && chmod -R +x /etc/s6-overlay/s6-rc.d/

# Install NodeJS and additional requirements
RUN apk add --no-cache \
    nodejs \
    npm \
    sqlite

# Create s6-rc.d structure dynamically (Eliminates Windows BOM/Line ending issues)
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-data/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/init-config/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/caddy/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/cpm/dependencies.d \
    && mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
    && printf "oneshot" > /etc/s6-overlay/s6-rc.d/init-data/type \
    && touch /etc/s6-overlay/s6-rc.d/init-data/up \
    && printf "#!/command/with-contenv bashio\nbashio::log.info \"Initializing /data directories...\"\nmkdir -p /data/db /data/certs /data/config /data/logs\nbashio::log.info \"Done.\"\n" > /etc/s6-overlay/s6-rc.d/init-data/run \
    && printf "oneshot" > /etc/s6-overlay/s6-rc.d/init-config/type \
    && touch /etc/s6-overlay/s6-rc.d/init-config/up \
    && touch /etc/s6-overlay/s6-rc.d/init-config/dependencies.d/init-data \
    && printf "#!/command/with-contenv bashio\nbashio::log.info \"--- ADD-ON CONFIGURATION VERSION ${BUILD_VERSION} ---\"\nSESSION_SECRET=\$(bashio::config 'session_secret')\nif bashio::var.is_empty \"\${SESSION_SECRET}\"; then\n    if [ ! -f /data/.session_secret ]; then\n        SESSION_SECRET=\$(openssl rand -base64 32)\n        echo \"\${SESSION_SECRET}\" > /data/.session_secret\n    else\n        SESSION_SECRET=\$(cat /data/.session_secret)\n    fi\nfi\nexport SESSION_SECRET\nexport ADMIN_USERNAME=\$(bashio::config 'admin_username')\nexport ADMIN_PASSWORD=\$(bashio::config 'admin_password')\nexport HTTP_PORT=\$(bashio::config 'http_port')\nexport HTTPS_PORT=\$(bashio::config 'https_port')\nexport DATABASE_URL=\"file:/data/db/caddy-proxy-manager.db\"\nexport CADDY_API_URL=\"http://localhost:2019\"\nexport PORT=\"3000\"\nS6_ENV_DIR=\"/run/s6/container_environment\"\n[ -d \"\$S6_ENV_DIR\" ] || S6_ENV_DIR=\"/var/run/s6/container_environment\"\nif [ -d \"\$S6_ENV_DIR\" ]; then\n    for var in SESSION_SECRET ADMIN_USERNAME ADMIN_PASSWORD HTTP_PORT HTTPS_PORT DATABASE_URL CADDY_API_URL PORT; do\n        printf \"%%s\" \"\${!var}\" > \"\$S6_ENV_DIR/\$var\"\n    done\n    printf \"%%s\" \"production\" > \"\$S6_ENV_DIR/NODE_ENV\"\nfi\nif [ ! -f /data/config/caddy.json ]; then\n    bashio::log.info \"Creating default caddy.json (HTTP_PORT=\${HTTP_PORT})...\"\n    printf '{\"apps\":{\"http\":{\"servers\":{\"srv0\":{\"listen\":[\":%s\"],\"routes\":[]}}}}}\\n' \"\${HTTP_PORT}\" > /data/config/caddy.json\nfi\nbashio::log.info \"Configuration loaded.\"\n" > /etc/s6-overlay/s6-rc.d/init-config/run \
    && printf "longrun" > /etc/s6-overlay/s6-rc.d/caddy/type \
    && touch /etc/s6-overlay/s6-rc.d/caddy/dependencies.d/init-config \
    && touch /etc/s6-overlay/s6-rc.d/caddy/dependencies.d/init-data \
    && printf "#!/command/with-contenv bashio\nS6_ENV_DIR=\"/run/s6/container_environment\"\n[ -d \"\$S6_ENV_DIR\" ] || S6_ENV_DIR=\"/var/run/s6/container_environment\"\nif [ -d \"\$S6_ENV_DIR\" ]; then\n    for var in \"\$S6_ENV_DIR\"/*; do export \"\$(basename \"\$var\")=\$(cat \"\$var\")\"; done\nfi\nif [ ! -f /data/config/caddy.json ]; then\n    _http_port=\"\${HTTP_PORT:-80}\"\n    bashio::log.warn \"caddy.json missing -- creating default on port \${_http_port}\"\n    mkdir -p /data/config\n    printf '{\"apps\":{\"http\":{\"servers\":{\"srv0\":{\"listen\":[\":%s\"],\"routes\":[]}}}}}\\n' \"\${_http_port}\" > /data/config/caddy.json\nfi\nbashio::log.info \"Starting Caddy...\"\nexec /usr/bin/caddy run --config /data/config/caddy.json --adapter json 2>&1\n" > /etc/s6-overlay/s6-rc.d/caddy/run \
    && printf "longrun" > /etc/s6-overlay/s6-rc.d/cpm/type \
    && touch /etc/s6-overlay/s6-rc.d/cpm/dependencies.d/caddy \
    && touch /etc/s6-overlay/s6-rc.d/cpm/dependencies.d/init-config \
    && printf "#!/command/with-contenv bashio\nbashio::log.info \"Starting caddy-proxy-manager...\"\nS6_ENV_DIR=\"/run/s6/container_environment\"\n[ -d \"\$S6_ENV_DIR\" ] || S6_ENV_DIR=\"/var/run/s6/container_environment\"\nif [ -d \"\$S6_ENV_DIR\" ]; then\n    for var in \"\$S6_ENV_DIR\"/*; do export \"\$(basename \"\$var\")=\$(cat \"\$var\")\"; done\nfi\nif [ -z \"\${SESSION_SECRET:-}\" ]; then\n    bashio::log.fatal \"SESSION_SECRET is not set -- init-config did not run correctly\"\n    exit 1\nfi\n{ echo \"SESSION_SECRET=\$SESSION_SECRET\"; echo \"ADMIN_USERNAME=\$ADMIN_USERNAME\"; echo \"ADMIN_PASSWORD=\$ADMIN_PASSWORD\"; echo \"DATABASE_URL=\$DATABASE_URL\"; echo \"CADDY_API_URL=\$CADDY_API_URL\"; echo \"PORT=\$PORT\"; echo \"NODE_ENV=production\"; } > /app/.env\ncd /app\nexec node server.js 2>&1\n" > /etc/s6-overlay/s6-rc.d/cpm/run \
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
