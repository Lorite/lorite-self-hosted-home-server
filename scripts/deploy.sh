#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
INVENTORY="local"
SKIP_DEPS=false
ASK_PASS=""
USE_FRESH=false # By default, use backups if available
CONFIGS_DIR="$(pwd)/configs"

# Load environment variables if .env file exists
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    set -a
    source .env
    set +a
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --inventory <local|remote|IP>  Deployment target (default: local)"
    echo "  -s, --skip-deps                    Skip dependency checks"
    echo "  -f, --fresh                        Start fresh (don't use existing backups)"
    echo "  -K, --ask-become-pass              Ask for sudo password"
    echo "  -h, --help                         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                 # Deploy locally (using backups if available)"
    echo "  $0 -i local                        # Deploy locally (explicit)"
    echo "  $0 -i remote                       # Deploy to remote server"
    echo "  $0 -i 192.168.1.100                # Deploy to specific IP"
    echo "  $0 -f                              # Deploy locally with fresh installation (ignore backups)"
    echo "  $0 -i remote -s                    # Deploy remotely, skip dependency checks"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    -i | --inventory)
        INVENTORY="$2"
        shift 2
        ;;
    -s | --skip-deps)
        SKIP_DEPS=true
        shift
        ;;
    -f | --fresh)
        USE_FRESH=true
        shift
        ;;
    -K | --ask-become-pass)
        ASK_PASS="--ask-become-pass"
        shift
        ;;
    -h | --help)
        show_usage
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Unknown option: $1${NC}"
        show_usage
        exit 1
        ;;
    esac
done

echo -e "${BLUE}🚀 Starting homelab deployment...${NC}"
echo -e "${BLUE}📍 Target: $INVENTORY${NC}"

# Dependency checks
if [ "$SKIP_DEPS" = false ]; then
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"

    # Check if Ansible is installed
    if ! command -v ansible &>/dev/null; then
        echo -e "${RED}❌ Ansible is not installed. Please install it first.${NC}"
        echo "   pip install ansible"
        exit 1
    fi

    # Check Docker installation for local deployment
    if [ "$INVENTORY" = "local" ]; then
        if ! command -v docker &>/dev/null; then
            echo -e "${YELLOW}⚠️  Docker not found locally. It will be installed by Ansible.${NC}"
        fi
    fi

    # Check SSH key for remote deployment
    if [ "$INVENTORY" = "remote" ] || [[ "$INVENTORY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if [ ! -f ~/.ssh/id_rsa ]; then
            echo -e "${YELLOW}⚠️  SSH key not found. Please set up SSH key authentication first.${NC}"
            exit 1
        fi
    fi
fi

# Determine inventory file and setup
INVENTORY_FILE=""
ANSIBLE_EXTRA_VARS=""

case $INVENTORY in
"local")
    INVENTORY_FILE="inventory/local.yml"
    echo -e "${GREEN}🏠 Deploying locally${NC}"
    ;;
"remote")
    INVENTORY_FILE="inventory/remote.yml"
    echo -e "${GREEN}🌐 Deploying to remote server${NC}"
    ;;
*)
    # Check if it's an IP address
    if [[ "$INVENTORY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        INVENTORY_FILE="inventory/remote.yml"
        ANSIBLE_EXTRA_VARS="--extra-vars ansible_host=$INVENTORY"
        echo -e "${GREEN}🌐 Deploying to $INVENTORY${NC}"
    else
        echo -e "${RED}❌ Invalid inventory option: $INVENTORY${NC}"
        show_usage
        exit 1
    fi
    ;;
esac

# Check if inventory file exists
if [ ! -f "ansible/$INVENTORY_FILE" ]; then
    echo -e "${RED}❌ Inventory file not found: ansible/$INVENTORY_FILE${NC}"
    exit 1
fi

# Create Docker network
echo -e "${YELLOW}📡 Creating Docker network...${NC}"
if [ "$INVENTORY" = "local" ]; then
    docker network create npm_network 2>/dev/null || echo "Network already exists"
else
    ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "docker network create npm_network || true"
fi

# Check if we should restore from backups
if [ "$USE_FRESH" = false ]; then
    echo -e "${YELLOW}🔄 Checking for backups to restore...${NC}"

    # Define paths based on inventory
    if [ "$INVENTORY" = "local" ]; then
        CONFIG_SERVICES_DIR="$CONFIGS_DIR/services"

        # Check for NPM configuration
        if [ -d "$CONFIG_SERVICES_DIR/npm" ] && [ -n "$(ls -A "$CONFIG_SERVICES_DIR/npm" 2>/dev/null)" ]; then
            echo -e "${GREEN}✅ Found NPM configuration backup${NC}"
            echo -e "${YELLOW}🔄 Restoring NPM configuration...${NC}"

            # Make sure npm_data volume exists
            docker volume inspect npm_data &>/dev/null || docker volume create npm_data

            # Restore NPM configuration
            docker run --rm -v npm_data:/npm -v "$CONFIG_SERVICES_DIR/npm":/backup alpine sh -c "cp -r /backup/* /npm/ 2>/dev/null || true"
            echo -e "${GREEN}✅ NPM configuration restored${NC}"
        else
            echo -e "${YELLOW}⚠️ No NPM configuration backup found${NC}"
        fi

        # Add restoration for other services here as needed

    else
        # Remote restoration
        REMOTE_CONFIG_SERVICES_DIR="/home/$USER/git/lorite-self-hosted-home-server/configs/services"

        echo -e "${YELLOW}🔄 Checking for remote backups...${NC}"

        # Check if NPM config exists and restore
        ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "
            if [ -d '$REMOTE_CONFIG_SERVICES_DIR/npm' ] && [ -n \"\$(ls -A '$REMOTE_CONFIG_SERVICES_DIR/npm' 2>/dev/null)\" ]; then
                echo 'Found NPM configuration backup'
                
                # Make sure npm_data volume exists
                docker volume inspect npm_data &>/dev/null || docker volume create npm_data
                
                # Restore NPM configuration
                docker run --rm -v npm_data:/npm -v '$REMOTE_CONFIG_SERVICES_DIR/npm':/backup alpine sh -c 'cp -r /backup/* /npm/ 2>/dev/null || true'
                echo 'NPM configuration restored'
            else
                echo 'No NPM configuration backup found'
            fi
        "
        # Add restoration for other services here as needed
    fi
else
    echo -e "${YELLOW}🆕 Using fresh installation (skipping backups)...${NC}"

    # For NPM, ensure we start with a fresh volume if it exists
    if [ "$INVENTORY" = "local" ]; then
        if docker volume inspect npm_data &>/dev/null; then
            echo -e "${YELLOW}🗑️  Removing existing NPM data volume...${NC}"
            docker volume rm npm_data || true
            docker volume create npm_data
        fi
    else
        ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "
            if docker volume inspect npm_data &>/dev/null; then
                echo 'Removing existing NPM data volume'
                docker volume rm npm_data || true
                docker volume create npm_data
            fi
        "
    fi
    # Add fresh setup for other services here as needed
fi

# Run Ansible playbook
echo -e "${YELLOW}🔧 Running Ansible playbook...${NC}"
cd ansible
ansible-playbook -i $INVENTORY_FILE $ANSIBLE_EXTRA_VARS $ASK_PASS playbooks/site.yml

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}🌐 Access your services:${NC}"

if [ "$INVENTORY" = "local" ]; then
    echo "  - Nginx Proxy Manager: http://localhost:81"
    echo "  - Hello World App: http://localhost:8080"
    echo "  - Portainer: http://localhost:9000"
    echo "  - Pi-hole: http://localhost:8081/admin (DNS on port 53)"
    echo "  - Immich: http://localhost:2283"
else
    SERVER_IP=$INVENTORY
    if [ "$INVENTORY" = "remote" ]; then
        SERVER_IP="your-server-ip"
    fi
    echo "  - Nginx Proxy Manager: http://$SERVER_IP:81"
    echo "  - Hello World App: http://$SERVER_IP:8080"
    echo "  - Portainer: http://$SERVER_IP:9000"
    echo "  - Pi-hole: http://$SERVER_IP:8081/admin (DNS on port 53)"
    echo "  - Immich: http://$SERVER_IP:2283"
fi

echo ""
echo -e "${YELLOW}🔐 Default NPM credentials:${NC}"
echo "  Email: admin@example.com / adminn@example.com"
echo "  Password: changeme"
echo ""
echo -e "${YELLOW}🔐 Default portainer credentials:${NC}"
echo "  Username: admin"
echo "  Password: myportainerpassword"
echo ""
echo -e "${YELLOW}🔐 Pi-hole credentials:${NC}"
echo "  Password: Set in .env file (PIHOLE_PASSWORD)"
echo ""
echo -e "${YELLOW}📸 Immich setup:${NC}"
echo "  - Create your admin account on first visit"
echo "  - Download mobile apps: iOS/Android"
echo "  - Configure IMMICH_DB_PASSWORD in .env file"
echo "  - Photos stored in: \${IMMICH_UPLOAD_LOCATION} (default: ./library)"
echo ""
echo -e "${YELLOW}💡 After setting up proxy hosts in NPM, you can access:${NC}"
if [ "$INVENTORY" = "local" ]; then
    echo "  In some browsers, you can use the following URLs:"
    echo "  - Hello World: http://hello.lvh.me/"
    echo "  - Portainer: http://portainer.lvh.me/"
    echo "  - Pi-hole: http://pihole.lvh.me/"
    echo "  - Immich: http://immich.lvh.me/"
else
    echo "  - Hello World: http://hello.$SERVER_IP"
    echo "  - Portainer: http://portainer.$SERVER_IP"
    echo "  - Pi-hole: http://pihole.$SERVER_IP"
    echo "  - Immich: http://immich.$SERVER_IP"
fi
