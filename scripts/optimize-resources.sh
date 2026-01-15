#!/bin/bash

# CyberPot Resource Optimization Script
# Sets resource mode and applies optimizations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
MODE="STANDARD"
DRY_RUN=false
RESTART=true

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Optimize CyberPot resource usage by setting resource mode.

OPTIONS:
    -m, --mode MODE        Set resource mode (LOW, STANDARD, HIGH)
    -d, --dry-run          Show what would be changed without applying
    -n, --no-restart       Don't restart services after applying changes
    -h, --help             Show this help message

EXAMPLES:
    $0 --mode LOW          # Set to LOW resource mode
    $0 --mode HIGH --dry-run  # Preview HIGH mode changes
    $0 -m STANDARD         # Set to STANDARD mode (default)

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -n|--no-restart)
            RESTART=false
            shift
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

# Validate mode
if [[ ! "$MODE" =~ ^(LOW|STANDARD|HIGH)$ ]]; then
    echo -e "${RED}Error: Invalid mode '$MODE'. Must be LOW, STANDARD, or HIGH.${NC}"
    exit 1
fi

echo -e "${GREEN}=== CyberPot Resource Optimization ===${NC}"
echo -e "Mode: ${YELLOW}$MODE${NC}"
echo -e "Dry Run: $DRY_RUN"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found. Are you in the CyberPot directory?${NC}"
    exit 1
fi

# Function to update .env file
update_env() {
    local key=$1
    local value=$2
    
    if grep -q "^${key}=" .env; then
        if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}Would update:${NC} $key=$value"
        else
            sed -i.bak "s|^${key}=.*|${key}=${value}|" .env
            echo -e "${GREEN}Updated:${NC} $key=$value"
        fi
    else
        if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}Would add:${NC} $key=$value"
        else
            echo "${key}=${value}" >> .env
            echo -e "${GREEN}Added:${NC} $key=$value"
        fi
    fi
}

# Set resource mode
echo -e "${GREEN}Configuring resource mode...${NC}"
update_env "CYBERPOT_RESOURCE_MODE" "$MODE"

# Set mode-specific configurations
case $MODE in
    LOW)
        echo -e "${GREEN}Applying LOW mode optimizations...${NC}"
        update_env "CYBERPOT_LOG_RETENTION_DAYS" "14"
        update_env "CYBERPOT_MAP_UPDATE_INTERVAL" "5000"
        echo -e "${YELLOW}Note: Elasticsearch heap will be set to 1GB${NC}"
        echo -e "${YELLOW}Note: Logstash heap will be set to 512MB${NC}"
        ;;
    STANDARD)
        echo -e "${GREEN}Applying STANDARD mode optimizations...${NC}"
        update_env "CYBERPOT_LOG_RETENTION_DAYS" "30"
        update_env "CYBERPOT_MAP_UPDATE_INTERVAL" "2000"
        echo -e "${YELLOW}Note: Elasticsearch heap will be set to 2GB${NC}"
        echo -e "${YELLOW}Note: Logstash heap will be set to 1GB${NC}"
        ;;
    HIGH)
        echo -e "${GREEN}Applying HIGH mode optimizations...${NC}"
        update_env "CYBERPOT_LOG_RETENTION_DAYS" "60"
        update_env "CYBERPOT_MAP_UPDATE_INTERVAL" "1000"
        echo -e "${YELLOW}Note: Elasticsearch heap will be set to 4GB${NC}"
        echo -e "${YELLOW}Note: Logstash heap will be set to 2GB${NC}"
        ;;
esac

# Show current configuration
echo ""
echo -e "${GREEN}Current Configuration:${NC}"
grep "^CYBERPOT_RESOURCE_MODE=" .env
grep "^CYBERPOT_LOG_RETENTION_DAYS=" .env
grep "^CYBERPOT_MAP_UPDATE_INTERVAL=" .env

# Restart services if requested
if [ "$RESTART" = true ] && [ "$DRY_RUN" = false ]; then
    echo ""
    echo -e "${YELLOW}Restarting CyberPot services...${NC}"
    
    if command -v systemctl &> /dev/null; then
        sudo systemctl restart cyberpot
        echo -e "${GREEN}Services restarted successfully${NC}"
    elif command -v docker-compose &> /dev/null; then
        docker-compose down
        docker-compose up -d
        echo -e "${GREEN}Services restarted successfully${NC}"
    else
        echo -e "${RED}Warning: Could not restart services automatically${NC}"
        echo -e "${YELLOW}Please restart CyberPot manually:${NC}"
        echo "  systemctl restart cyberpot"
        echo "  OR"
        echo "  docker-compose down && docker-compose up -d"
    fi
elif [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "${YELLOW}Dry run complete. No changes were made.${NC}"
    echo -e "Run without --dry-run to apply changes."
fi

echo ""
echo -e "${GREEN}=== Optimization Complete ===${NC}"
echo -e "Resource mode set to: ${YELLOW}$MODE${NC}"
echo ""
echo -e "Monitor resource usage with:"
echo -e "  ${YELLOW}./scripts/monitor-resources.sh${NC}"
echo ""
