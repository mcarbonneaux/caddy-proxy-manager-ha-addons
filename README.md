# Caddy Proxy Manager - Home Assistant Add-ons

This repository contains a Home Assistant add-on that runs **Caddy** and [**Caddy Proxy Manager (CPM)**](https://github.com/fuomag9/caddy-proxy-manager) in a single container.

## About the Project

This add-on combines the power of the **Caddy** web server/reverse proxy with the user-friendly management interface of **Caddy Proxy Manager**. It allows you to easily manage your redirection hosts, SSL certificates (automatically managed by Caddy), and reverse proxy rules directly from the Home Assistant interface.

### Key Features

*   **Caddy & CPM**: Both processes run in parallel, supervised by `s6-overlay`.
*   **Automatic SSL Certificates**: Benefit from Caddy's native and automatic certificate management.
*   **Ingress Access**: Access the management interface directly via the Home Assistant sidebar without unnecessarily exposing additional ports.
*   **Host Network Mode**: Uses the host network (`host_network: true`) to preserve real client IP addresses (essential for geo-blocking and traffic analysis).

## Installation

To install this add-on in your Home Assistant instance:

1.  Go to **Settings** -> **Add-ons**.
2.  Click the **Add-on Store** button in the bottom right.
3.  Click the three vertical dots in the top right and choose **Repositories**.
4.  Add the URL of this repository: `https://github.com/mcarbonneaux/caddy-proxy-manager-ha-addons`
5.  Search for "Caddy Proxy Manager" in the list and click **Install**.

## Configuration

Before starting the add-on, you must configure the following options:

*   `session_secret`: A random string (min. 32 characters) used to secure interface sessions.
*   `admin_username`: The username for CPM administration (default: `admin`).
*   `admin_password`: The password for administration (it is strongly recommended to use a strong password).
*   `http_port`: Port used by Caddy for HTTP traffic (default: `80`).
*   `https_port`: Port used by Caddy for HTTPS traffic (default: `443`).

## Usage

Once the add-on is started:

1.  Click **Open Web UI** or use the "Caddy Proxy Manager" link in your sidebar if you enabled the option.
2.  Log in with the configured credentials.
3.  Start adding your domains and configuring your proxies.

## Technical Architecture

The add-on uses the base image from [fuomag9/caddy-proxy-manager](https://github.com/fuomag9/caddy-proxy-manager) with the Caddy binary added. Both are managed by `s6-overlay`.

Data is persisted in Home Assistant's `/data` directory:
*   `/data/db/`: SQLite database.
*   `/data/certs/`: Certificates managed by Caddy.
*   `/data/config/`: Caddy configuration.

## Development & Build

The build process is automated using GitHub Actions. To trigger a new build and release:

1.  **Update the upstream version** (if necessary) in `.github/workflows/build.yaml`.
2.  **Create and push a new tag** following the `v*.*-ha.*` format. For example:
    ```bash
    git tag v1.4-ha.2
    git push origin master --tags
    ```
3.  The GitHub Action will:
    *   Build multi-arch images (`amd64`, `aarch64`).
    *   Push the images to **GitHub Container Registry (GHCR)**.
    *   Automatically update the `version` in `caddy-proxy-manager/config.yaml` and image references in `caddy-proxy-manager/build.yaml`.

### Troubleshooting

If the add-on does not appear in the store after adding the repository:
- Go to the **Add-on Store**, click the three dots in the top right, and select **Check for updates**.
- Check the **Supervisor logs** (Settings > System > Logs > Supervisor).
- Note: This add-on only supports `amd64` and `aarch64`. It will be hidden on unsupported architectures like `armv7`.

## Acknowledgments

This project is built upon the excellent work of [fuomag9](https://github.com/fuomag9) on Caddy Proxy Manager.
