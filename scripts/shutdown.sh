#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
INVENTORY="local"
BACKUP_BEFORE_SHUTDOWN=false
ASK_PASS=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --inventory <local|remote|IP>  Server target (default: local)"
    echo "  -b, --backup                       Create backup before shutdown"
    echo "  -K, --ask-become-pass              Ask for sudo password"
    echo "  -h, --help                         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                 # Shut down local server"
    echo "  $0 -i remote                       # Shut down remote server"
    echo "  $0 -b                              # Back up and shut down local server"
    echo "  $0 -i remote -b                    # Back up and shut down remote server"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    -i | --inventory)
        INVENTORY="$2"
        shift 2
        ;;
    -b | --backup)
        BACKUP_BEFORE_SHUTDOWN=true
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

# Display the start message
echo -e "${BLUE}🛑 Shutting down homelab services...${NC}"
echo -e "${BLUE}📍 Target: $INVENTORY${NC}"

# Determine inventory file and extra vars
INVENTORY_FILE=""
ANSIBLE_EXTRA_VARS=""

case $INVENTORY in
"local")
    INVENTORY_FILE="inventory/local.yml"
    echo -e "${GREEN}🏠 Shutting down locally${NC}"
    ;;
"remote")
    INVENTORY_FILE="inventory/remote.yml"
    echo -e "${GREEN}🌐 Shutting down remote server${NC}"
    ;;
*)
    # Check if it's an IP address
    if [[ "$INVENTORY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        INVENTORY_FILE="inventory/remote.yml"
        ANSIBLE_EXTRA_VARS="--extra-vars ansible_host=$INVENTORY"
        echo -e "${GREEN}🌐 Shutting down $INVENTORY${NC}"
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

# Create backup before shutdown if requested
if [ "$BACKUP_BEFORE_SHUTDOWN" = true ]; then
    echo -e "${YELLOW}💾 Creating backup before shutdown...${NC}"

    if [ "$INVENTORY" = "local" ]; then
        # Run local backup
        ./scripts/backup.sh
    else
        # Run remote backup
        ./scripts/backup.sh -i $INVENTORY
    fi

    # Check if backup was successful
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️ Backup completed with warnings. Continuing with shutdown...${NC}"
    else
        echo -e "${GREEN}✅ Pre-shutdown backup completed successfully.${NC}"
    fi
fi

# Shut down services
echo -e "${YELLOW}🔽 Stopping Docker containers...${NC}"

if [ "$INVENTORY" = "local" ]; then
    # Local shutdown

    # Find all docker-compose files and stop them
    echo -e "${YELLOW}📂 Finding Docker Compose services...${NC}"

    # Stop Nginx Proxy Manager
    if [ -f "docker-compose/nginx-proxy-manager/docker-compose.yml" ]; then
        echo -e "${YELLOW}🔽 Stopping Nginx Proxy Manager...${NC}"
        docker-compose -f docker-compose/nginx-proxy-manager/docker-compose.yml down
    fi

    # Stop Hello App
    if [ -f "docker-compose/hello-app/docker-compose.yml" ]; then
        echo -e "${YELLOW}🔽 Stopping Hello App...${NC}"
        docker-compose -f docker-compose/hello-app/docker-compose.yml down
    fi

    # Stop Portainer
    if [ -f "docker-compose/portainer/docker-compose.yml" ]; then
        echo -e "${YELLOW}🔽 Stopping Portainer...${NC}"
        docker-compose -f docker-compose/portainer/docker-compose.yml down
    fi

    echo -e "${GREEN}✅ All services stopped locally.${NC}"

else
    # Remote shutdown using Ansible
    echo -e "${YELLOW}🔽 Stopping services on remote server...${NC}"

    # Use Ansible to stop the services
    cd ansible
    ansible-playbook -i $INVENTORY_FILE $ANSIBLE_EXTRA_VARS $ASK_PASS playbooks/shutdown.yml

    # If shutdown playbook doesn't exist, use ad-hoc commands
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️ Shutdown playbook not found, using direct commands...${NC}"
        cd ..

        ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "cd ~/git/lorite-self-hosted-home-server && \
            docker-compose -f docker-compose/nginx-proxy-manager/docker-compose.yml down && \
            docker-compose -f docker-compose/hello-app/docker-compose.yml down && \
            docker-compose -f docker-compose/portainer/docker-compose.yml down"
    fi
fi

# Final status check
echo -e "${YELLOW}🔍 Checking remaining containers...${NC}"

if [ "$INVENTORY" = "local" ]; then
    # Check if there are any remaining containers related to our services
    RUNNING_CONTAINERS=$(docker ps --filter "network=npm_network" --format "{{.Names}}" 2>/dev/null)

    if [ -n "$RUNNING_CONTAINERS" ]; then
        echo -e "${YELLOW}⚠️ Some containers are still running:${NC}"
        echo "$RUNNING_CONTAINERS"
        echo -e "${YELLOW}Forcing shutdown of remaining containers...${NC}"
        docker stop $(docker ps --filter "network=npm_network" -q) 2>/dev/null || true
    fi
else
    # Check remote containers
    ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "docker ps --filter 'network=npm_network' --format '{{.Names}}'"

    # Force stop if needed
    ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "docker stop \$(docker ps --filter 'network=npm_network' -q) 2>/dev/null || true"
fi

echo -e "${GREEN}✅ Server shutdown completed successfully.${NC}"
echo ""
echo -e "${BLUE}💡 To restart the server, use:${NC}"

if [ "$INVENTORY" = "local" ]; then
    echo "  ./scripts/deploy.sh"
else
    echo "  ./scripts/deploy.sh -i $INVENTORY"
fi
echo "  or the appropriate VS Code task"
