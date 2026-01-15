#!/bin/bash

# CyberPot Resource Monitoring Script
# Real-time resource usage monitoring

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default duration (0 = continuous)
DURATION=0
INTERVAL=5

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            cat << EOF
Usage: $0 [OPTIONS]

Monitor CyberPot resource usage in real-time.

OPTIONS:
    -d, --duration SECONDS    Monitor for specified duration (0 = continuous)
    -i, --interval SECONDS    Update interval (default: 5)
    -h, --help                Show this help message

EXAMPLES:
    $0                        # Continuous monitoring
    $0 -d 300                 # Monitor for 5 minutes
    $0 -d 600 -i 10           # Monitor for 10 minutes, update every 10s

EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if running in CyberPot directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found. Are you in the CyberPot directory?${NC}"
    exit 1
fi

# Function to get container stats
get_container_stats() {
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" | \
        grep -E "elasticsearch|logstash|kibana|map_" | \
        head -10
}

# Function to get disk usage
get_disk_usage() {
    df -h ~/cyberpot/data 2>/dev/null | tail -1 | awk '{print $3 " / " $2 " (" $5 ")"}'
}

# Function to get system memory
get_system_memory() {
    free -h | grep "Mem:" | awk '{print $3 " / " $2 " (" int($3/$2*100) "%)"}'
}

# Function to get backend health
get_backend_health() {
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        curl -s http://localhost:3000/health | jq -r '.status' 2>/dev/null || echo "unknown"
    else
        echo "offline"
    fi
}

# Function to display dashboard
display_dashboard() {
    clear
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║        CyberPot Resource Monitor                               ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Resource mode
    MODE=$(grep "^CYBERPOT_RESOURCE_MODE=" .env 2>/dev/null | cut -d'=' -f2 || echo "UNKNOWN")
    echo -e "${BLUE}Resource Mode:${NC} ${YELLOW}$MODE${NC}"
    echo ""
    
    # System overview
    echo -e "${BLUE}System Overview:${NC}"
    echo -e "  Memory:     $(get_system_memory)"
    echo -e "  Disk:       $(get_disk_usage)"
    echo -e "  Backend:    $(get_backend_health)"
    echo ""
    
    # Container stats
    echo -e "${BLUE}Container Resource Usage:${NC}"
    get_container_stats
    echo ""
    
    # Elasticsearch health
    if curl -s http://localhost:64298/_cluster/health > /dev/null 2>&1; then
        ES_HEALTH=$(curl -s http://localhost:64298/_cluster/health | jq -r '.status' 2>/dev/null || echo "unknown")
        ES_NODES=$(curl -s http://localhost:64298/_cluster/health | jq -r '.number_of_nodes' 2>/dev/null || echo "0")
        echo -e "${BLUE}Elasticsearch:${NC}"
        echo -e "  Health:     $ES_HEALTH"
        echo -e "  Nodes:      $ES_NODES"
        echo ""
    fi
    
    # Timestamp
    echo -e "${BLUE}Last Update:${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    
    if [ "$DURATION" -gt 0 ]; then
        ELAPSED=$(($(date +%s) - START_TIME))
        REMAINING=$((DURATION - ELAPSED))
        echo -e "${BLUE}Time Remaining:${NC} ${REMAINING}s"
    else
        echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
    fi
}

# Main monitoring loop
START_TIME=$(date +%s)
ITERATIONS=0

echo -e "${GREEN}Starting resource monitoring...${NC}"
sleep 1

while true; do
    display_dashboard
    
    # Check if duration exceeded
    if [ "$DURATION" -gt 0 ]; then
        ELAPSED=$(($(date +%s) - START_TIME))
        if [ "$ELAPSED" -ge "$DURATION" ]; then
            echo ""
            echo -e "${GREEN}Monitoring complete.${NC}"
            break
        fi
    fi
    
    sleep "$INTERVAL"
    ITERATIONS=$((ITERATIONS + 1))
done
