#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
INVENTORY="local"
BACKUP_DIR_DEFAULT="$(pwd)/configs/backups"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --inventory <local|remote|IP>  Deployment target (default: local)"
    echo "  -d, --backup-dir <path>            Backup directory (default: $BACKUP_DIR_DEFAULT)"
    echo "  -h, --help                         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                 # Backup local deployment"
    echo "  $0 -i remote                       # Backup remote deployment"
    echo "  $0 -i 192.168.1.100 -d /backups   # Backup specific IP to custom directory"
}

# Parse command line arguments
BACKUP_DIR="$BACKUP_DIR_DEFAULT"
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--inventory)
            INVENTORY="$2"
            shift 2
            ;;
        -d|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        -h|--help)
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

DATE=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}💾 Creating backup...${NC}"
echo -e "${BLUE}📍 Target: $INVENTORY${NC}"
echo -e "${BLUE}📁 Backup dir: $BACKUP_DIR${NC}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

if [ "$INVENTORY" = "local" ]; then
    # Local backup
    echo -e "${YELLOW}🏠 Creating local backup...${NC}"
    
    # Backup Docker volumes
    docker run --rm \
        -v portainer_data:/data \
        -v npm_data:/npm \
        -v npm_letsencrypt:/letsencrypt \
        -v "$BACKUP_DIR":/backup \
        alpine tar czf "/backup/volumes_$DATE.tar.gz" -C / data npm letsencrypt
    
    # Backup configurations to configs directory
    PROJECT_ROOT=$(pwd)
    mkdir -p "$PROJECT_ROOT/configs/backups"
    
    # Copy service configurations to configs directory
    echo -e "${YELLOW}📁 Copying service configs to project configs directory...${NC}"
    mkdir -p "$PROJECT_ROOT/configs/services"
    
    # Copy NPM configuration if it exists
    if docker volume inspect npm_data &>/dev/null; then
        echo -e "${YELLOW}📋 Backing up NPM configuration...${NC}"
        TEMP_DIR=$(mktemp -d)
        docker run --rm -v npm_data:/npm -v "$TEMP_DIR":/backup alpine sh -c "cp -r /npm/* /backup/ 2>/dev/null || true"
        mkdir -p "$PROJECT_ROOT/configs/services/npm"
        cp -r "$TEMP_DIR"/* "$PROJECT_ROOT/configs/services/npm/" 2>/dev/null || true
        rm -rf "$TEMP_DIR"
    fi
    
    # Create a backup archive of the configs directory
    tar czf "$BACKUP_DIR/configs_$DATE.tar.gz" -C "$PROJECT_ROOT" configs/services/ 2>/dev/null || echo "No configs to backup"
    
else
    # Remote backup
    echo -e "${YELLOW}🌐 Creating remote backup...${NC}"
    
    # Determine inventory file and extra vars
    INVENTORY_FILE="inventory/remote.yml"
    ANSIBLE_EXTRA_VARS=""
    
    if [[ "$INVENTORY" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        ANSIBLE_EXTRA_VARS="--extra-vars ansible_host=$INVENTORY"
    fi
    
    # Backup Docker volumes
    ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "docker run --rm -v portainer_data:/data -v npm_data:/npm -v npm_letsencrypt:/letsencrypt -v $BACKUP_DIR:/backup alpine tar czf /backup/volumes_$DATE.tar.gz -C / data npm letsencrypt"
    
    # Backup configurations to configs directory on remote server
    PROJECT_ROOT="/home/$USER/git/lorite-self-hosted-home-server"
    
    # Create directories on remote server
    ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "mkdir -p $PROJECT_ROOT/configs/backups $PROJECT_ROOT/configs/services/npm"
    
    # Copy NPM configuration if it exists
    echo -e "${YELLOW}📋 Backing up remote NPM configuration...${NC}"
    ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "
        if docker volume inspect npm_data &>/dev/null; then
            TEMP_DIR=\$(mktemp -d)
            docker run --rm -v npm_data:/npm -v \$TEMP_DIR:/backup alpine sh -c 'cp -r /npm/* /backup/ 2>/dev/null || true'
            mkdir -p $PROJECT_ROOT/configs/services/npm
            cp -r \$TEMP_DIR/* $PROJECT_ROOT/configs/services/npm/ 2>/dev/null || true
            rm -rf \$TEMP_DIR
        fi
    "
    
    # Create backup archive on remote server
    ansible homelab -i ansible/$INVENTORY_FILE $ANSIBLE_EXTRA_VARS -m shell -a "tar czf $BACKUP_DIR/configs_$DATE.tar.gz -C $PROJECT_ROOT configs/services/ 2>/dev/null || true"
fi

echo -e "${GREEN}✅ Backup completed: $BACKUP_DIR${NC}"
echo -e "${GREEN}📦 Files created:${NC}"
ls -la "$BACKUP_DIR"/*_$DATE.tar.gz 2>/dev/null || echo "  No backup files found"