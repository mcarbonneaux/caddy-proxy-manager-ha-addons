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
EOF
chmod 600 /data/config/addon.env

# Créer caddy.json par défaut si absent
if [ ! -f /data/config/caddy.json ]; then
    echo "[INFO] init-config: creating default caddy.json on port ${HTTP_PORT}..."
    printf '{"apps":{"http":{"servers":{"srv0":{"listen":[":%s"],"routes":[]}}}}}\n' \
        "${HTTP_PORT}" > /data/config/caddy.json
fi

echo "[INFO] init-config: done."
