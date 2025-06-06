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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -i, --inventory <local|remote|IP>  Deployment target (default: local)"
    echo "  -h, --help                         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                 # Update local deployment"
    echo "  $0 -i remote                       # Update remote deployment"
    echo "  $0 -i 192.168.1.100               # Update specific IP"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--inventory)
            INVENTORY="$2"
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

echo -e "${BLUE}🔄 Updating homelab services...${NC}"
echo -e "${BLUE}📍 Target: $INVENTORY${NC}"

# Pull latest changes from Git
echo -e "${YELLOW}📥 Pulling latest changes from Git...${NC}"
git pull origin main

# Re-run deployment
echo -e "${YELLOW}🚀 Re-running deployment...${NC}"
./scripts/deploy.sh -i $INVENTORY -s

echo -e "${GREEN}✅ Update completed!${NC}"