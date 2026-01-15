#!/bin/bash

# CyberPot Profile Management Script
# Apply, create, and manage resource profiles

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
ACTION="apply"
PROFILE_NAME=""
PROFILES_DIR="profiles"

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [PROFILE_NAME]

Manage CyberPot resource profiles.

OPTIONS:
    -a, --action ACTION    Action: apply, list, create, validate (default: apply)
    -h, --help             Show this help message

AVAILABLE PROFILES:
    raspberry-pi           Optimized for Raspberry Pi 4/5
    cloud-small            Cloud micro/small instances
    enterprise             High-performance production

EXAMPLES:
    $0 raspberry-pi        # Apply Raspberry Pi profile
    $0 --action list       # List available profiles
    $0 --action create my-profile  # Create custom profile

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--action)
            ACTION="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            PROFILE_NAME="$1"
            shift
            ;;
    esac
done

echo -e "${GREEN}=== CyberPot Profile Management ===${NC}"
echo ""

case $ACTION in
    list)
        echo -e "${GREEN}Available Profiles:${NC}"
        echo ""
        for profile in "$PROFILES_DIR"/*.profile; do
            if [ -f "$profile" ]; then
                name=$(basename "$profile" .profile)
                desc=$(grep "^PROFILE_DESCRIPTION=" "$profile" | cut -d'=' -f2- | tr -d '"')
                ram=$(grep "^PROFILE_MIN_RAM_GB=" "$profile" | cut -d'=' -f2)
                echo -e "${BLUE}$name${NC}"
                echo -e "  Description: $desc"
                echo -e "  Min RAM: ${ram}GB"
                echo ""
            fi
        done
        ;;
    
    apply)
        if [ -z "$PROFILE_NAME" ]; then
            echo -e "${RED}Error: Profile name required${NC}"
            usage
        fi
        
        PROFILE_FILE="$PROFILES_DIR/$PROFILE_NAME.profile"
        
        if [ ! -f "$PROFILE_FILE" ]; then
            echo -e "${RED}Error: Profile '$PROFILE_NAME' not found${NC}"
            echo -e "Run '$0 --action list' to see available profiles"
            exit 1
        fi
        
        echo -e "${GREEN}Applying profile: ${YELLOW}$PROFILE_NAME${NC}"
        echo ""
        
        # Backup current .env
        if [ -f ".env" ]; then
            cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
            echo -e "${YELLOW}Backed up current .env${NC}"
        fi
        
        # Apply profile settings
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ "$key" =~ ^#.*$ ]] && continue
            [[ -z "$key" ]] && continue
            
            # Skip profile metadata
            [[ "$key" =~ ^PROFILE_.*$ ]] && continue
            
            # Update or add to .env
            if grep -q "^${key}=" .env 2>/dev/null; then
                sed -i.tmp "s|^${key}=.*|${key}=${value}|" .env
                echo -e "${GREEN}Updated:${NC} $key=$value"
            else
                echo "${key}=${value}" >> .env
                echo -e "${GREEN}Added:${NC} $key=$value"
            fi
        done < "$PROFILE_FILE"
        
        # Clean up temp files
        rm -f .env.tmp
        
        echo ""
        echo -e "${GREEN}✓ Profile applied successfully${NC}"
        echo -e "${YELLOW}Restart CyberPot for changes to take effect${NC}"
        ;;
    
    create)
        if [ -z "$PROFILE_NAME" ]; then
            echo -e "${RED}Error: Profile name required${NC}"
            usage
        fi
        
        PROFILE_FILE="$PROFILES_DIR/$PROFILE_NAME.profile"
        
        if [ -f "$PROFILE_FILE" ]; then
            echo -e "${RED}Error: Profile '$PROFILE_NAME' already exists${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}Creating custom profile: ${YELLOW}$PROFILE_NAME${NC}"
        echo ""
        
        # Copy template
        cp "$PROFILES_DIR/custom.profile.template" "$PROFILE_FILE" 2>/dev/null || {
            echo -e "${YELLOW}Template not found, creating from current .env${NC}"
            
            cat > "$PROFILE_FILE" << EOF
# CyberPot Resource Profile: $PROFILE_NAME
# Custom profile created $(date +%Y-%m-%d)

# Resource Mode
CYBERPOT_RESOURCE_MODE=STANDARD

# Profile Metadata
PROFILE_NAME="$PROFILE_NAME"
PROFILE_DESCRIPTION="Custom profile"
PROFILE_MIN_RAM_GB=8
PROFILE_MIN_DISK_GB=128
EOF
            
            # Add current settings
            grep "^CYBERPOT_" .env >> "$PROFILE_FILE" 2>/dev/null || true
        }
        
        echo -e "${GREEN}✓ Profile created: $PROFILE_FILE${NC}"
        echo -e "${YELLOW}Edit the file to customize settings${NC}"
        ;;
    
    validate)
        if [ -z "$PROFILE_NAME" ]; then
            echo -e "${RED}Error: Profile name required${NC}"
            usage
        fi
        
        PROFILE_FILE="$PROFILES_DIR/$PROFILE_NAME.profile"
        
        if [ ! -f "$PROFILE_FILE" ]; then
            echo -e "${RED}Error: Profile '$PROFILE_NAME' not found${NC}"
            exit 1
        fi
        
        echo -e "${GREEN}Validating profile: ${YELLOW}$PROFILE_NAME${NC}"
        echo ""
        
        # Check required fields
        required_fields=("CYBERPOT_RESOURCE_MODE" "PROFILE_NAME" "PROFILE_DESCRIPTION")
        valid=true
        
        for field in "${required_fields[@]}"; do
            if ! grep -q "^${field}=" "$PROFILE_FILE"; then
                echo -e "${RED}✗ Missing required field: $field${NC}"
                valid=false
            else
                echo -e "${GREEN}✓ Found: $field${NC}"
            fi
        done
        
        if [ "$valid" = true ]; then
            echo ""
            echo -e "${GREEN}✓ Profile is valid${NC}"
        else
            echo ""
            echo -e "${RED}✗ Profile validation failed${NC}"
            exit 1
        fi
        ;;
    
    *)
        echo -e "${RED}Unknown action: $ACTION${NC}"
        usage
        ;;
esac

echo ""
