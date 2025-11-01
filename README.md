# Self-Hosted Home Server

A comprehensive solution for deploying and managing self-hosted services in a home lab environment using Docker containers and Ansible for deployment and configuration management.

## Project Overview

This self-hosted home server setup allows you to easily deploy various services either locally or on a remote server. It's designed to be modular, maintainable, and easy to use, even for those new to self-hosting.

## Features

- **Docker-based**: All services run in Docker containers for isolation and easy management
- **Ansible automation**: Consistent deployment and configuration across environments
- **Local or remote deployment**: Run on your local machine or deploy to a remote server
- **Configuration management**: Centralized configuration files for all services
- **Backup functionality**: Built-in backup script for container data
- **VS Code integration**: Tasks for common operations

## Services

Current services included:

- **Hello App**: Example application to verify deployment
- **Nginx Proxy Manager**: Reverse proxy for accessing services with configuration backup/restore
- **Portainer**: Web UI for Docker management
- **Pi-hole**: Network-wide ad blocker and DNS server (web interface on port 8081, DNS on port 53)
- **Immich**: Self-hosted photo and video backup solution (Google Photos alternative)

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Ansible (for deployment)
- Git (for updates)

### Deployment Options

The project supports different deployment targets:

- **Local**: Deploy to the local machine
- **Remote**: Deploy to a remote server defined in Ansible inventory
- **Specific IP**: Deploy to a specific IP address

### Installation

1.  Clone this repository:
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```
2.  Create and activate a Python virtual environment:
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate
    ```
3.  Install the required Python dependencies:
    ```bash
    pip install -r requirements.txt
    ```
4.  Copy `.env.example` to `.env` and customize as needed:
    ```bash
    cp .env.example .env
    ```
    
    **Important**: Configure the following in `.env`:
    - Set your server's IP address for `PIHOLE_HOST_IP`
    - Set a strong password for `PIHOLE_PASSWORD` (used for Pi-hole web interface)
    - Set a strong password for `IMMICH_DB_PASSWORD` (used for Immich database)
    - Optionally adjust `IMMICH_TZ` to your timezone
    - Optionally adjust `IMMICH_UPLOAD_LOCATION` for photo/video storage location
    
    ```bash
    # Find your IP address
    hostname -I | awk '{print $1}'
    
    # Edit .env and update the configuration
    nano .env
    ```
    
5.  For remote deployment, copy `ansible/inventory/remote.yml.example` to `ansible/inventory/remote.yml` and update it with your server's details.
6.  Run the deployment script with the `-K` flag to be prompted for your sudo password:
    ```bash
    ./scripts/deploy.sh -K
    ```

## VS Code Integration

The project includes VS Code tasks for common operations:

- Deploying (local, remote, with sudo, fresh installation)
- Updating (local, remote)
- Backing up (local, remote, custom directory)
- Shutting down (local, remote, with backup)
- Checking Docker status (containers, networks, volumes)

To use these tasks, open the Command Palette in VS Code (`Ctrl+Shift+P`) and search for "Tasks: Run Task".

## Usage

### Deploy Script Options

```bash
./scripts/deploy.sh [OPTIONS]

Options:
  -i, --inventory <local|remote|IP>  Deployment target (default: local)
  -s, --skip-deps                    Skip dependency checks
  -f, --fresh                        Start fresh (don't use existing backups)
  -K, --ask-become-pass              Ask for sudo password
  -h, --help                         Show help message
```

### Update Script Options

```bash
./scripts/update.sh [OPTIONS]

Options:
  -i, --inventory <local|remote|IP>  Update target (default: local)
  -h, --help                         Show help message
```

### Backup Script Options

```bash
./scripts/backup.sh [OPTIONS]

Options:
  -i, --inventory <local|remote|IP>  Backup target (default: local)
  -d, --backup-dir <path>            Custom backup directory
  -h, --help                         Show help message
```

### Shutdown Script Options

```bash
./scripts/shutdown.sh [OPTIONS]

Options:
  -i, --inventory <local|remote|IP>  Server target (default: local)
  -b, --backup                       Create backup before shutdown
  -K, --ask-become-pass              Ask for sudo password
  -h, --help                         Show help message
```

## Best Practices

When working with this project:

1. Always test changes locally before deploying to a remote server
2. Use the VS Code tasks for common operations
3. Keep environment-specific configuration in .env files
4. Update documentation when adding new services or features
5. Follow the existing project structure when adding new components

## Automation with Ansible

Ansible is used for:

- System setup (installing Docker and dependencies)
- Service deployment (deploying Docker containers)
- Configuration management

Key playbooks:

- `site.yml`: Main entry point
- `setup-system.yml`: System preparation
- `deploy-services.yml`: Service deployment

## Accessing Services

After deployment, services are accessible at the following URLs (local deployment):

- **Nginx Proxy Manager**: http://localhost:81
  - Default Email: `admin@example.com` or `adminn@example.com`
  - Default Password: `changeme`
  - Use this to set up reverse proxy for other services

- **Hello World App**: http://localhost:8080
  - Simple test application to verify deployment

- **Portainer**: http://localhost:9000
  - Default Username: `admin`
  - Default Password: `myportainerpassword`
  - Docker container management interface

- **Pi-hole**: http://localhost:8081/admin
  - Password: Set in `.env` file as `PIHOLE_PASSWORD` (default: `admin` if not set)
  - DNS server on port 53 (bound to your primary network interface)
  - **Note**: Automatically configured to avoid conflicts with system DNS services

- **Immich**: http://localhost:2283
  - Create your admin account on first visit
  - Mobile apps available for iOS and Android
  - Supports automatic photo/video backup from mobile devices
  - Machine learning features for face recognition and smart search
  - **Storage**: Photos and videos stored in location specified by `IMMICH_UPLOAD_LOCATION` in `.env`
  - **Database**: PostgreSQL data stored in Docker volume `immich_postgres_data`

### Using Pi-hole as Your DNS Server

Pi-hole is configured to bind to your primary network interface on port 53 using the `PIHOLE_HOST_IP` environment variable from your `.env` file. This avoids conflicts with system services like systemd-resolved or LXC's dnsmasq.

#### Configure Your Network to Use Pi-hole

1. **Verify your server's IP address** (should match `PIHOLE_HOST_IP` in `.env`):
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. **Configure your router:**
   - Access your router's admin panel
   - Find DNS settings (usually under DHCP, LAN, or Internet settings)
   - Set Primary DNS to your server's IP address
   - Set Secondary DNS to a fallback like `1.1.1.1` or `8.8.8.8`
   - Save and reboot your router

3. **Restart devices** or renew DHCP leases to pick up the new DNS settings

**Important Notes:**
- Your server must have a **static IP address** or DHCP reservation
- When Pi-hole is down, you will lose DNS resolution (keep a backup DNS configured)
- All devices on your network will automatically use Pi-hole for DNS and ad-blocking
- Pi-hole binds to your primary network interface only, not all interfaces

### Setting Up Reverse Proxy

Use Nginx Proxy Manager to set up friendly URLs for your services:

1. Access Nginx Proxy Manager at http://localhost:81
2. Log in with default credentials
3. Add proxy hosts for each service
4. Access services using custom domains (e.g., http://pihole.lvh.me)

## Troubleshooting

### sudo-rs Compatibility

This project is compatible with both standard `sudo` and `sudo-rs`. The Ansible configuration automatically uses `sudo.ws` as the become executable, which is required for `sudo-rs` to work properly with Ansible's password prompts.

If you experience any sudo-related issues, verify your sudo version:
```bash
sudo --version
```

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

- TODO

## Support

- TODO
