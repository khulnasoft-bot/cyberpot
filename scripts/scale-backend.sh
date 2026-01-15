#!/bin/bash

# CyberPot Backend Scaling Script
# Scale backend instances and configure load balancing

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
INSTANCES=1
ACTION="scale"
BACKEND_IMAGE="cyberpot-backend:latest"

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Scale CyberPot backend instances.

OPTIONS:
    -i, --instances NUM    Number of backend instances (default: 1)
    -a, --action ACTION    Action: scale, up, down, status (default: scale)
    -h, --help             Show this help message

EXAMPLES:
    $0 --instances 3       # Scale to 3 instances
    $0 --action status     # Show current scaling status
    $0 --action down       # Stop all scaled instances

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--instances)
            INSTANCES="$2"
            shift 2
            ;;
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

echo -e "${GREEN}=== CyberPot Backend Scaling ===${NC}"
echo -e "Action: ${YELLOW}$ACTION${NC}"
echo ""

# Check if docker-compose.scale.yml exists
if [ ! -f "docker-compose.scale.yml" ]; then
    echo -e "${RED}Error: docker-compose.scale.yml not found${NC}"
    exit 1
fi

case $ACTION in
    scale)
        echo -e "${GREEN}Scaling backend to $INSTANCES instances...${NC}"
        docker-compose -f docker-compose.scale.yml up -d --scale backend=$INSTANCES
        echo -e "${GREEN}✓ Scaled to $INSTANCES instances${NC}"
        ;;
    
    up)
        echo -e "${GREEN}Starting scaled backend...${NC}"
        docker-compose -f docker-compose.scale.yml up -d
        echo -e "${GREEN}✓ Backend started${NC}"
        ;;
    
    down)
        echo -e "${YELLOW}Stopping scaled backend...${NC}"
        docker-compose -f docker-compose.scale.yml down
        echo -e "${GREEN}✓ Backend stopped${NC}"
        ;;
    
    status)
        echo -e "${GREEN}Current backend instances:${NC}"
        docker-compose -f docker-compose.scale.yml ps backend
        echo ""
        echo -e "${GREEN}Load balancer status:${NC}"
        docker-compose -f docker-compose.scale.yml ps haproxy
        ;;
    
    *)
        echo -e "${RED}Unknown action: $ACTION${NC}"
        usage
        ;;
esac

# Show health status
if [ "$ACTION" != "down" ]; then
    echo ""
    echo -e "${GREEN}Health check:${NC}"
    sleep 2
    for i in $(seq 1 $INSTANCES); do
        if curl -s http://localhost:3000/health > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Backend responding${NC}"
            break
        else
            echo -e "${YELLOW}Waiting for backend...${NC}"
            sleep 1
        fi
    done
fi

echo ""
echo -e "${GREEN}=== Scaling Complete ===${NC}"
