# Caddy Proxy Manager HA Add-on Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Home Assistant add-on that runs Caddy + caddy-proxy-manager in a single container, distributed as a pre-built multi-arch image on ghcr.io.

**Architecture:** One container runs two processes (Caddy + CPM Next.js app) supervised by s6-overlay. The image is built from `ghcr.io/fuomag9/caddy-proxy-manager` with the Caddy binary injected via multi-stage Dockerfile. HA ingress exposes the UI; host networking gives Caddy real client IPs.

**Tech Stack:** Docker (buildx + QEMU), s6-overlay, GitHub Actions, Home Assistant add-on API (config.yaml / options.json / bashio), Caddy, Next.js (caddy-proxy-manager upstream).

---

## File Map

| File | Role |
|------|------|
| `repository.yaml` | HA add-on repository manifest |
| `caddy-proxy-manager/config.yaml` | Add-on metadata: ports, ingress, options schema, architectures |
| `caddy-proxy-manager/build.yaml` | Declares multi-arch image refs for HA Supervisor |
| `caddy-proxy-manager/Dockerfile` | Multi-stage: Caddy binary + CPM base + rootfs |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-data/type` | s6 oneshot type file |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-data/up` | s6 oneshot dependency marker |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-data/run` | Creates /data subdirectories |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/type` | s6 oneshot type file |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/up` | Depends on init-data |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/run` | Reads options.json, writes env file |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/type` | s6 longrun type file |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/dependencies.d/init-config` | Depends on init-config |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/run` | Starts Caddy process |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/type` | s6 longrun type file |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/dependencies.d/caddy` | Depends on caddy |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/run` | Starts CPM Next.js process |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/caddy` | Adds caddy to user bundle |
| `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/cpm` | Adds cpm to user bundle |
| `.github/workflows/build.yaml` | Multi-arch build + push to ghcr.io on tag push |
| `.github/workflows/update-upstream.yaml` | Weekly PR to bump UPSTREAM_VERSION |

---

## Task 1: Repository scaffold & HA manifest

**Files:**
- Create: `repository.yaml`
- Create: `.gitignore`

- [ ] **Step 1: Create `repository.yaml`**

```yaml
name: Caddy Proxy Manager
url: https://github.com/mcarbonneaux/caddy-proxy-manager-ha-addons
maintainer: mcarbonneaux
```

- [ ] **Step 2: Create `.gitignore`**

```gitignore
.idea/
*.iml
```

- [ ] **Step 3: Commit**

```bash
git add repository.yaml .gitignore
git commit -m "feat: add HA repository manifest and gitignore"
```

---

## Task 2: Add-on `config.yaml`

**Files:**
- Create: `caddy-proxy-manager/config.yaml`

The `config.yaml` is the core HA add-on descriptor. It defines everything the Supervisor needs to know: metadata, supported architectures, ports, ingress, and the options schema that drives the UI form.

- [ ] **Step 1: Create `caddy-proxy-manager/config.yaml`**

```yaml
name: Caddy Proxy Manager
version: "1.4-ha.1"
slug: caddy_proxy_manager
description: Caddy reverse proxy managed by caddy-proxy-manager web UI
url: https://github.com/mcarbonneaux/caddy-proxy-manager-ha-addons
arch:
  - amd64
  - aarch64
  - armv7
  - armhf
  - i386

host_network: true

ports:
  80/tcp: 80
  443/tcp: 443

ports_description:
  80/tcp: HTTP
  443/tcp: HTTPS

ingress: true
ingress_port: 3000
panel_icon: mdi:shield-check
panel_title: Caddy Proxy Manager

options:
  session_secret: ""
  admin_username: admin
  admin_password: ""
  http_port: 80
  https_port: 443

schema:
  session_secret: str
  admin_username: str
  admin_password: str
  http_port: int
  https_port: int

map:
  - data:rw

image: ghcr.io/mcarbonneaux/caddy-proxy-manager-ha:{arch}-{version}
```

- [ ] **Step 2: Commit**

```bash
git add caddy-proxy-manager/config.yaml
git commit -m "feat: add add-on config.yaml"
```

---

## Task 3: Add-on `build.yaml`

**Files:**
- Create: `caddy-proxy-manager/build.yaml`

`build.yaml` tells the HA Supervisor which image to pull per architecture. The image name pattern must match `image` in `config.yaml`.

- [ ] **Step 1: Create `caddy-proxy-manager/build.yaml`**

```yaml
build_from:
  amd64: ghcr.io/mcarbonneaux/caddy-proxy-manager-ha:amd64-1.4-ha.1
  aarch64: ghcr.io/mcarbonneaux/caddy-proxy-manager-ha:aarch64-1.4-ha.1
  armv7: ghcr.io/mcarbonneaux/caddy-proxy-manager-ha:armv7-1.4-ha.1
  armhf: ghcr.io/mcarbonneaux/caddy-proxy-manager-ha:armhf-1.4-ha.1
  i386: ghcr.io/mcarbonneaux/caddy-proxy-manager-ha:i386-1.4-ha.1

squash: false
```

- [ ] **Step 2: Commit**

```bash
git add caddy-proxy-manager/build.yaml
git commit -m "feat: add add-on build.yaml with multi-arch image refs"
```

---

## Task 4: Dockerfile

**Files:**
- Create: `caddy-proxy-manager/Dockerfile`

Multi-stage build: extract the Caddy binary from the official image, then layer it onto the CPM upstream image along with the rootfs scripts.

- [ ] **Step 1: Create `caddy-proxy-manager/Dockerfile`**

```dockerfile
ARG BUILD_FROM
ARG UPSTREAM_VERSION=1.4

FROM caddy:latest AS caddy-bin

FROM ghcr.io/fuomag9/caddy-proxy-manager:${UPSTREAM_VERSION}

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
```

Note: `BUILD_FROM` is declared but unused here because we use the upstream CPM image directly as the base. The HA build system passes it; declaring it silences the warning.

- [ ] **Step 2: Commit**

```bash
git add caddy-proxy-manager/Dockerfile
git commit -m "feat: add multi-stage Dockerfile (Caddy binary + CPM base)"
```

---

## Task 5: s6-overlay — `init-data` service

**Files:**
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-data/type`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-data/up`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-data/run`

`init-data` is a oneshot that creates the expected `/data` subdirectories on first boot.

- [ ] **Step 1: Create `type` file**

```
oneshot
```

- [ ] **Step 2: Create `up` file** (empty — no dependency, runs first)

```
```

(empty file)

- [ ] **Step 3: Create `run` script**

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Initializing /data directories..."
mkdir -p /data/db /data/certs /data/config /data/logs
bashio::log.info "Done."
```

- [ ] **Step 4: Add to user bundle**

```bash
mkdir -p caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d
touch caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/init-data
```

- [ ] **Step 5: Commit**

```bash
git add caddy-proxy-manager/rootfs/
git commit -m "feat: add s6 init-data oneshot service"
```

---

## Task 6: s6-overlay — `init-config` service

**Files:**
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/type`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/dependencies.d/init-data`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/run`

`init-config` reads the HA options (`/data/options.json`) via bashio and exports environment variables for CPM. It writes them to `/var/run/s6/container_environment/` so s6 injects them into child processes automatically.

- [ ] **Step 1: Create `type` file**

```
oneshot
```

- [ ] **Step 2: Create dependency on `init-data`**

```bash
mkdir -p caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/dependencies.d
touch caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/init-config/dependencies.d/init-data
```

- [ ] **Step 3: Create `run` script**

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Reading add-on options..."

SESSION_SECRET=$(bashio::config 'session_secret')
ADMIN_USERNAME=$(bashio::config 'admin_username')
ADMIN_PASSWORD=$(bashio::config 'admin_password')
HTTP_PORT=$(bashio::config 'http_port')
HTTPS_PORT=$(bashio::config 'https_port')

# Validate required fields
if bashio::var.is_empty "${SESSION_SECRET}" || [ ${#SESSION_SECRET} -lt 32 ]; then
  bashio::exit.nok "session_secret must be at least 32 characters long"
fi
if bashio::var.is_empty "${ADMIN_PASSWORD}"; then
  bashio::exit.nok "admin_password must not be empty"
fi

# Write env vars for s6 child processes
printf "%s" "${SESSION_SECRET}"  > /var/run/s6/container_environment/SESSION_SECRET
printf "%s" "${ADMIN_USERNAME}"  > /var/run/s6/container_environment/ADMIN_USERNAME
printf "%s" "${ADMIN_PASSWORD}"  > /var/run/s6/container_environment/ADMIN_PASSWORD
printf "%s" "${HTTP_PORT}"       > /var/run/s6/container_environment/HTTP_PORT
printf "%s" "${HTTPS_PORT}"      > /var/run/s6/container_environment/HTTPS_PORT
printf "%s" "file:/data/db/caddy-proxy-manager.db" > /var/run/s6/container_environment/DATABASE_URL
printf "%s" "http://localhost:2019"                 > /var/run/s6/container_environment/CADDY_API_URL

# BASE_URL: use ingress URL if available, otherwise localhost
if bashio::var.has_value "$(bashio::addon.ingress_url 2>/dev/null)"; then
  INGRESS_URL=$(bashio::addon.ingress_url)
  printf "%s" "${INGRESS_URL}" > /var/run/s6/container_environment/BASE_URL
else
  printf "%s" "http://localhost:3000" > /var/run/s6/container_environment/BASE_URL
fi

bashio::log.info "Configuration loaded."
```

- [ ] **Step 4: Add to user bundle**

```bash
touch caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/init-config
```

- [ ] **Step 5: Commit**

```bash
git add caddy-proxy-manager/rootfs/
git commit -m "feat: add s6 init-config oneshot — inject HA options as env vars"
```

---

## Task 7: s6-overlay — `caddy` longrun service

**Files:**
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/type`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/dependencies.d/init-config`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/run`

The `caddy` longrun starts the Caddy binary. Caddy is configured via the Admin API by CPM at runtime; we start it with an empty config and let CPM push its configuration.

- [ ] **Step 1: Create `type` file**

```
longrun
```

- [ ] **Step 2: Create dependency on `init-config`**

```bash
mkdir -p caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/dependencies.d
touch caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/caddy/dependencies.d/init-config
```

- [ ] **Step 3: Create `run` script**

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting Caddy..."
exec /usr/bin/caddy run --config /data/config/Caddyfile --adapter caddyfile 2>&1 || \
  exec /usr/bin/caddy run 2>&1
```

The `|| exec /usr/bin/caddy run` fallback starts Caddy with no config file if `/data/config/Caddyfile` doesn't exist yet (first boot). CPM will push its config via the Admin API on port 2019.

- [ ] **Step 4: Add to user bundle**

```bash
touch caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/caddy
```

- [ ] **Step 5: Commit**

```bash
git add caddy-proxy-manager/rootfs/
git commit -m "feat: add s6 caddy longrun service"
```

---

## Task 8: s6-overlay — `cpm` longrun service

**Files:**
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/type`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/dependencies.d/caddy`
- Create: `caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/run`

The `cpm` longrun starts the caddy-proxy-manager Next.js app. It depends on `caddy` being up first so the Admin API on port 2019 is available when CPM initializes.

- [ ] **Step 1: Create `type` file**

```
longrun
```

- [ ] **Step 2: Create dependency on `caddy`**

```bash
mkdir -p caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/dependencies.d
touch caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/cpm/dependencies.d/caddy
```

- [ ] **Step 3: Create `run` script**

The CPM upstream image starts via `node server.js` or `next start`. We need to find the actual entrypoint from the upstream image and replicate it here.

```bash
#!/usr/bin/with-contenv bashio

bashio::log.info "Starting caddy-proxy-manager..."

# The upstream image entrypoint is node /app/server.js (Next.js standalone output)
cd /app
exec node server.js 2>&1
```

> **Implementation note:** Before finalising this script, verify the upstream entrypoint by inspecting the image:
> ```bash
> docker inspect ghcr.io/fuomag9/caddy-proxy-manager:1.4 --format '{{json .Config.Cmd}}'
> docker inspect ghcr.io/fuomag9/caddy-proxy-manager:1.4 --format '{{json .Config.Entrypoint}}'
> ```
> Adjust the `exec` line if the entrypoint differs.

- [ ] **Step 4: Add to user bundle**

```bash
touch caddy-proxy-manager/rootfs/etc/s6-overlay/s6-rc.d/user/contents.d/cpm
```

- [ ] **Step 5: Commit**

```bash
git add caddy-proxy-manager/rootfs/
git commit -m "feat: add s6 cpm longrun service"
```

---

## Task 9: GitHub Actions — multi-arch build workflow

**Files:**
- Create: `.github/workflows/build.yaml`

Builds the image for all 5 arches on every `v*.*-ha.*` tag push and pushes to ghcr.io.

- [ ] **Step 1: Create `.github/workflows/build.yaml`**

```yaml
name: Build & Push

on:
  push:
    tags:
      - "v*.*-ha.*"

env:
  UPSTREAM_VERSION: "1.4"
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/caddy-proxy-manager-ha

jobs:
  build:
    name: Build ${{ matrix.arch }}
    runs-on: ubuntu-latest
    strategy:
      matrix:
        include:
          - arch: amd64
            platform: linux/amd64
          - arch: aarch64
            platform: linux/arm64
          - arch: armv7
            platform: linux/arm/v7
          - arch: armhf
            platform: linux/arm/v6
          - arch: i386
            platform: linux/386

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to ghcr.io
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract tag version
        id: version
        run: echo "VERSION=${GITHUB_REF_NAME#v}" >> $GITHUB_OUTPUT

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: caddy-proxy-manager
          platforms: ${{ matrix.platform }}
          push: true
          build-args: |
            UPSTREAM_VERSION=${{ env.UPSTREAM_VERSION }}
          tags: |
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ matrix.arch }}-${{ steps.version.outputs.VERSION }}
            ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ matrix.arch }}-latest

  update-config:
    name: Update config.yaml version
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Extract tag version
        id: version
        run: echo "VERSION=${GITHUB_REF_NAME#v}" >> $GITHUB_OUTPUT

      - name: Update version in config.yaml
        run: |
          sed -i "s/^version:.*/version: \"${{ steps.version.outputs.VERSION }}\"/" caddy-proxy-manager/config.yaml

      - name: Update build.yaml image refs
        run: |
          VERSION=${{ steps.version.outputs.VERSION }}
          REGISTRY=${{ env.REGISTRY }}
          IMAGE=${{ env.IMAGE_NAME }}
          for arch in amd64 aarch64 armv7 armhf i386; do
            sed -i "s|${arch}: .*|${arch}: ${REGISTRY}/${IMAGE}:${arch}-${VERSION}|" caddy-proxy-manager/build.yaml
          done

      - name: Commit and push updated config
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add caddy-proxy-manager/config.yaml caddy-proxy-manager/build.yaml
          git diff --cached --quiet || git commit -m "chore: bump version to ${{ steps.version.outputs.VERSION }}"
          git push origin HEAD:main
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/build.yaml
git commit -m "feat: add multi-arch GitHub Actions build workflow"
```

---

## Task 10: GitHub Actions — upstream update workflow

**Files:**
- Create: `.github/workflows/update-upstream.yaml`

Runs weekly, checks if a new release of caddy-proxy-manager is available on ghcr.io, and opens a PR bumping `UPSTREAM_VERSION` in `build.yaml`.

- [ ] **Step 1: Create `.github/workflows/update-upstream.yaml`**

```yaml
name: Check Upstream Update

on:
  schedule:
    - cron: "0 8 * * 1"  # Every Monday at 08:00 UTC
  workflow_dispatch:

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Get latest upstream release
        id: upstream
        run: |
          LATEST=$(curl -s https://api.github.com/repos/fuomag9/caddy-proxy-manager/releases/latest \
            | jq -r '.tag_name' | sed 's/^v//')
          echo "LATEST=${LATEST}" >> $GITHUB_OUTPUT

      - name: Get current UPSTREAM_VERSION in workflow
        id: current
        run: |
          CURRENT=$(grep 'UPSTREAM_VERSION:' .github/workflows/build.yaml | head -1 | awk '{print $2}' | tr -d '"')
          echo "CURRENT=${CURRENT}" >> $GITHUB_OUTPUT

      - name: Open PR if update available
        if: steps.upstream.outputs.LATEST != steps.current.outputs.CURRENT
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          LATEST: ${{ steps.upstream.outputs.LATEST }}
          CURRENT: ${{ steps.current.outputs.CURRENT }}
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          BRANCH="upstream-update-${LATEST}"
          git checkout -b "${BRANCH}"
          sed -i "s/UPSTREAM_VERSION: \"${CURRENT}\"/UPSTREAM_VERSION: \"${LATEST}\"/" .github/workflows/build.yaml
          git add .github/workflows/build.yaml
          git commit -m "chore: bump upstream caddy-proxy-manager to v${LATEST}"
          git push origin "${BRANCH}"
          gh pr create \
            --title "chore: bump upstream caddy-proxy-manager to v${LATEST}" \
            --body "Automated PR: upstream caddy-proxy-manager released v${LATEST} (was v${CURRENT})." \
            --base main \
            --head "${BRANCH}"
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/update-upstream.yaml
git commit -m "feat: add weekly upstream version check workflow"
```

---

## Task 11: Verify ingress compatibility & smoke test

**Files:** No new files — verification step.

This task verifies that the CPM Next.js app works behind the HA ingress path prefix. The ingress injects an `X-Ingress-Path` header with a value like `/api/hassio_ingress/xxxxxxxx`. Next.js must be configured with a matching `basePath` or a Caddy rewrite must strip the prefix.

- [ ] **Step 1: Inspect the upstream image entrypoint**

```bash
docker pull ghcr.io/fuomag9/caddy-proxy-manager:1.4
docker inspect ghcr.io/fuomag9/caddy-proxy-manager:1.4 --format '{{json .Config.Cmd}}'
docker inspect ghcr.io/fuomag9/caddy-proxy-manager:1.4 --format '{{json .Config.Entrypoint}}'
docker inspect ghcr.io/fuomag9/caddy-proxy-manager:1.4 --format '{{json .Config.Env}}'
```

Update `cpm/run` in Task 8 if the `exec` command differs from `node server.js`.

- [ ] **Step 2: Check if CPM supports a configurable basePath**

```bash
docker run --rm ghcr.io/fuomag9/caddy-proxy-manager:1.4 \
  grep -r "basePath\|BASE_PATH\|NEXT_PUBLIC_BASE" /app/next.config* 2>/dev/null || echo "not found"
```

- [ ] **Step 3a: If `basePath` is configurable via env var** — add to `init-config/run`:

```bash
printf "%s" "${INGRESS_URL}" > /var/run/s6/container_environment/NEXT_PUBLIC_BASE_PATH
# (or whatever the env var name is — substitute from step 2 findings)
```

- [ ] **Step 3b: If `basePath` is NOT configurable** — add a Caddy reverse proxy layer inside the container that strips the ingress prefix before forwarding to CPM. Add to `init-config/run`:

```bash
# Write a Caddyfile that rewrites the ingress prefix and proxies to CPM
INGRESS_PATH=$(bashio::addon.ingress_url 2>/dev/null | sed 's|http://[^/]*||')
cat > /data/config/Caddyfile <<EOF
:2020 {
    route ${INGRESS_PATH}/* {
        uri strip_prefix ${INGRESS_PATH}
        reverse_proxy localhost:3000
    }
}
EOF
printf "%s" "http://localhost:2020" > /var/run/s6/container_environment/INGRESS_PROXY_PORT
```

And update `config.yaml` `ingress_port` to `2020` if this path is taken.

- [ ] **Step 4: Build and test locally**

```bash
cd caddy-proxy-manager
docker build \
  --build-arg UPSTREAM_VERSION=1.4 \
  --platform linux/amd64 \
  -t cpm-ha-test:local .
docker run --rm -it \
  -e SESSION_SECRET="thisIsATestSecretThatIsLongEnough1234" \
  -e ADMIN_USERNAME="admin" \
  -e ADMIN_PASSWORD="Admin1234!" \
  -p 3000:3000 -p 2019:2019 -p 80:80 -p 443:443 \
  cpm-ha-test:local
```

Expected: Caddy starts on port 2019 (Admin API), CPM UI accessible at `http://localhost:3000`.

- [ ] **Step 5: Commit any fixes found during verification**

```bash
git add -A
git commit -m "fix: adjust cpm run script and ingress handling after smoke test"
```

---

## Task 12: First release tag

- [ ] **Step 1: Ensure `main` branch is up to date**

```bash
git checkout -b main 2>/dev/null || git checkout main
git merge master
git push -u origin main
```

- [ ] **Step 2: Push first tag to trigger the build workflow**

```bash
git tag v1.4-ha.1
git push origin v1.4-ha.1
```

Expected: GitHub Actions `build.yaml` workflow triggers, builds 5-arch images, pushes to `ghcr.io/mcarbonneaux/caddy-proxy-manager-ha`.

- [ ] **Step 3: Verify images on ghcr.io**

Go to `https://github.com/mcarbonneaux?tab=packages` and confirm all 5 arch tags are published.

- [ ] **Step 4: Install and test in Home Assistant**

In HA: Settings → Add-ons → Add-on Store → ⋮ → Repositories → add `https://github.com/mcarbonneaux/caddy-proxy-manager-ha-addons`

Confirm the add-on appears, installs, and the UI loads via the HA sidebar ingress panel.

---

## Self-Review Notes

- **Spec coverage:** repository manifest ✓, config.yaml ✓, build.yaml ✓, Dockerfile ✓, s6 services ✓, ports ✓, ingress ✓, /data ✓, CI/CD ✓, upstream update ✓, versioning ✓
- **Known open item:** CPM ingress basePath compatibility — Task 11 handles both code paths (env var vs. Caddy rewrite) so the implementer can choose based on what they find
- **`<owner>` resolved:** using `mcarbonneaux` (from user email `mcarbonneaux@gmail.com`) throughout — adjust if GitHub username differs
