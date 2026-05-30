#!/bin/bash
set -e

OPTIONS="/data/options.json"

echo "[INFO] init-config: creating directories..."
mkdir -p /data/db /data/certs /data/config /data/logs

echo "[INFO] init-config: reading ${OPTIONS}..."

SESSION_SECRET=$(jq -r '.session_secret // empty' "${OPTIONS}" 2>/dev/null || true)
if [ -z "${SESSION_SECRET}" ]; then
    if [ -f /data/.session_secret ]; then
        echo "[INFO] init-config: loading session_secret from storage..."
        SESSION_SECRET=$(cat /data/.session_secret)
    else
        echo "[INFO] init-config: generating random session_secret..."
        SESSION_SECRET=$(openssl rand -base64 32)
        echo "${SESSION_SECRET}" > /data/.session_secret
    fi
fi

ADMIN_USERNAME=$(jq -r '.admin_username // "admin"' "${OPTIONS}" 2>/dev/null || echo "admin")
ADMIN_PASSWORD=$(jq -r '.admin_password // ""'       "${OPTIONS}" 2>/dev/null || true)
HTTP_PORT=$(jq -r '.http_port // 80'                 "${OPTIONS}" 2>/dev/null || echo "80")
HTTPS_PORT=$(jq -r '.https_port // 443'              "${OPTIONS}" 2>/dev/null || echo "443")

echo "[INFO] init-config: HTTP_PORT=${HTTP_PORT} HTTPS_PORT=${HTTPS_PORT} SECRET_LEN=${#SESSION_SECRET}"

# Write addon.env — chargé par caddy et cpm via envFiles
cat > /data/config/addon.env << EOF
SESSION_SECRET=${SESSION_SECRET}
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
HTTP_PORT=${HTTP_PORT}
HTTPS_PORT=${HTTPS_PORT}
DATABASE_URL=file:/data/db/caddy-proxy-manager.db
CADDY_API_URL=http://localhost:2019
PORT=3000
NODE_ENV=production
HOSTNAME=$(hostname -i | awk '{print $1}')
EOF
chmod 600 /data/config/addon.env

# Créer caddy.json par défaut si absent ou si le port ne correspond pas
CADDY_JSON=/data/config/caddy.json
NEED_CREATE=true
if [ -f "${CADDY_JSON}" ]; then
    CURRENT_PORT=$(jq -r '.apps.http.servers.srv0.listen[0] // ""' "${CADDY_JSON}" 2>/dev/null | tr -d ':')
    if [ "${CURRENT_PORT}" = "${HTTP_PORT}" ]; then
        NEED_CREATE=false
    else
        echo "[INFO] init-config: caddy.json port mismatch (was :${CURRENT_PORT}, now :${HTTP_PORT}), regenerating..."
    fi
fi
if [ "${NEED_CREATE}" = "true" ]; then
    echo "[INFO] init-config: creating default caddy.json on port ${HTTP_PORT}..."
    printf '{"apps":{"http":{"servers":{"srv0":{"listen":[":%s"],"routes":[]}}}}}\n' \
        "${HTTP_PORT}" > "${CADDY_JSON}"
fi

echo "[INFO] init-config: done."
