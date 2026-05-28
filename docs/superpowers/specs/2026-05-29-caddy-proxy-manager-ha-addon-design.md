# Caddy Proxy Manager — Home Assistant Add-on Design

## Overview

A single Home Assistant add-on that runs Caddy (reverse proxy) and caddy-proxy-manager (management UI) together in one container. The add-on is distributed as a pre-built multi-arch image on ghcr.io and installable as a third-party HA add-on repository.

Upstream project: https://github.com/fuomag9/caddy-proxy-manager

---

## Repository Structure

```
caddy-proxy-manager-ha-addons/
├── repository.yaml                        # HA add-on repository manifest
├── caddy-proxy-manager/
│   ├── config.yaml                        # Add-on metadata, ports, ingress, options
│   ├── Dockerfile                         # Multi-arch image: CPM base + Caddy binary
│   ├── build.yaml                         # Target architectures for HA Supervisor
│   └── rootfs/
│       └── etc/s6-overlay/s6-rc.d/
│           ├── init-data/                 # oneshot: setup /data subdirectories
│           ├── init-config/               # oneshot: inject HA options → env vars
│           ├── caddy/                     # longrun: Caddy process
│           └── cpm/                       # longrun: caddy-proxy-manager Next.js process
└── .github/
    └── workflows/
        ├── build.yaml                     # Multi-arch build + push to ghcr.io on tag
        └── update-upstream.yaml           # Weekly check for new upstream versions (opens PR)
```

---

## Architecture

### Container

One container runs two processes supervised by s6-overlay:

1. **Caddy** — the actual reverse proxy, listens on host network ports 80/443
2. **caddy-proxy-manager (CPM)** — the Next.js management UI, listens internally on port 3000

The two communicate via `http://localhost:2019` (Caddy Admin API), which is never exposed on the network.

### Network

`host_network: true` — required so Caddy sees real client IPs for geo-blocking, WAF, and traffic analytics. Without host networking, Docker bridge masquerading would replace client IPs with the Docker bridge IP, breaking CPM features that depend on real IPs.

### Image

Base image: `ghcr.io/fuomag9/caddy-proxy-manager:${UPSTREAM_VERSION}`

The Caddy binary is added on top via a multi-stage Dockerfile:

```dockerfile
ARG UPSTREAM_VERSION
FROM caddy:latest AS caddy-bin

FROM ghcr.io/fuomag9/caddy-proxy-manager:${UPSTREAM_VERSION}

COPY --from=caddy-bin /usr/bin/caddy /usr/bin/caddy
COPY rootfs/ /

CMD ["/init"]
```

---

## Supported Architectures

All five HA architectures via `docker buildx` + QEMU:

- `amd64`
- `aarch64`
- `armv7`
- `armhf`
- `i386`

---

## Ports

| Port | Protocol | Exposure | Configurable | Default |
|------|----------|----------|--------------|---------|
| 80 | TCP | Host network | Yes (HA UI) | 80 |
| 443 | TCP | Host network | Yes (HA UI) | 443 |
| 3000 | TCP | Ingress only | Optional, disabled by default | — |
| 2019 | TCP | Internal only | No | 2019 |

Port 3000 is accessible via HA ingress by default. A direct network port can be enabled manually by the user for advanced setups.

---

## Ingress (UI Access)

The management UI is exposed via HA ingress by default:

- No port 3000 exposed on the local network
- Access via HA sidebar, protected by HA session authentication
- `panel_icon: mdi:shield-check`, `panel_title: Caddy Proxy Manager`

```yaml
ingress: true
ingress_port: 3000
```

**Known risk:** caddy-proxy-manager (Next.js) must handle the dynamic ingress path prefix injected by the HA Supervisor (`X-Ingress-Path` header). If the upstream does not support `basePath` natively, an internal Caddy rewrite rule will be needed to strip the prefix before forwarding to the Next.js app. This must be verified during implementation.

---

## Persistent Data

All persistent data is stored under `/data` (HA add-on data directory):

```
/data/
├── db/                  # SQLite database
├── certs/               # Caddy-managed TLS certificates
├── config/              # Caddy configuration
└── logs/                # Traffic and access logs
```

The `init-data` s6 oneshot creates these directories on first start if absent.

---

## User-Configurable Options (HA UI)

| Option | Type | Required | Default | Description |
|--------|------|----------|---------|-------------|
| `SESSION_SECRET` | string | Yes | — | Min 32 chars, used by CPM for session signing |
| `ADMIN_USERNAME` | string | Yes | `admin` | CPM admin username |
| `ADMIN_PASSWORD` | string | Yes | — | CPM admin password (min 12 chars, mixed case + special chars) |
| `HTTP_PORT` | int | No | `80` | Port Caddy listens on for HTTP |
| `HTTPS_PORT` | int | No | `443` | Port Caddy listens on for HTTPS |

---

## Process Supervision (s6-overlay)

s6-overlay manages startup order and process restart:

```
init-data   (oneshot)  →  creates /data subdirectories
init-config (oneshot)  →  reads /data/options.json, exports env vars
caddy       (longrun)  →  Caddy binary, depends on init-config
cpm         (longrun)  →  Next.js CPM app, depends on caddy
```

Environment variables injected by `init-config` from `/data/options.json`:

| Env var | Value |
|---------|-------|
| `SESSION_SECRET` | from options |
| `ADMIN_USERNAME` | from options |
| `ADMIN_PASSWORD` | from options |
| `DATABASE_URL` | `file:/data/db/caddy-proxy-manager.db` |
| `CADDY_API_URL` | `http://localhost:2019` |
| `BASE_URL` | ingress URL or `http://localhost:3000` |

---

## Versioning & CI/CD

### Version convention

`v<upstream_version>-ha.<patch>` — e.g., `v0.5.2-ha.1`, `v0.5.2-ha.2`

This distinguishes upstream CPM version from add-on-level fixes. The `version` field in `config.yaml` follows this convention.

### `UPSTREAM_VERSION`

Defined as a variable in the GitHub Actions build workflow. Updated manually when bumping the upstream CPM version, then a new tag is pushed to trigger a build.

### `build.yaml` workflow (triggered on `v*.*.*-ha.*` tag push)

1. Checkout repository
2. Setup QEMU + `docker buildx` for 5-arch cross-compilation
3. Login to ghcr.io with `GITHUB_TOKEN`
4. Build and push multi-arch image:
   - `ghcr.io/<owner>/caddy-proxy-manager-ha:<tag>`
   - `ghcr.io/<owner>/caddy-proxy-manager-ha:latest`
5. Update `version` in `config.yaml` automatically

### `update-upstream.yaml` workflow (weekly, optional)

Checks for new releases of `ghcr.io/fuomag9/caddy-proxy-manager`. If a newer version is found, opens a PR bumping `UPSTREAM_VERSION` in the build workflow.

---

## HA Repository Manifest (`repository.yaml`)

```yaml
name: Caddy Proxy Manager
url: https://github.com/<owner>/caddy-proxy-manager-ha-addons
maintainer: <owner>
```

Users install the add-on by adding the repository URL in HA → Settings → Add-ons → Add-on Store → repositories.
