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
5.  For remote deployment, copy `ansible/inventory/remote.yml.example` to `ansible/inventory/remote.yml` and update it with your server's details.
6.  Run the deployment script with appropriate options. For example, to deploy locally:
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
  -r, --restore-npm                  Restore Nginx Proxy Manager configuration
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

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

- TODO

## Support

- TODO
