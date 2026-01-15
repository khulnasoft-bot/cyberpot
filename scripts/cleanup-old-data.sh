#!/bin/bash

# CyberPot Data Cleanup Script
# Removes old logs and compresses archives

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
DRY_RUN=false
RETENTION_DAYS=30
COMPRESS=true
VERBOSE=false

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Clean up old CyberPot logs and data.

OPTIONS:
    -d, --days DAYS          Retention period in days (default: 30)
    -n, --dry-run            Show what would be deleted without deleting
    -c, --no-compress        Don't compress old logs
    -v, --verbose            Verbose output
    -h, --help               Show this help message

EXAMPLES:
    $0                       # Clean logs older than 30 days
    $0 --days 14             # Clean logs older than 14 days
    $0 --dry-run             # Preview what would be deleted

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -c|--no-compress)
            COMPRESS=false
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
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

echo -e "${GREEN}=== CyberPot Data Cleanup ===${NC}"
echo -e "Retention: ${YELLOW}${RETENTION_DAYS} days${NC}"
echo -e "Dry Run: $DRY_RUN"
echo ""

# Check if data directory exists
if [ ! -d "data" ]; then
    echo -e "${RED}Error: data directory not found. Are you in the CyberPot directory?${NC}"
    exit 1
fi

# Calculate space before cleanup
SPACE_BEFORE=$(du -sh data | cut -f1)
echo -e "Current data directory size: ${YELLOW}${SPACE_BEFORE}${NC}"
echo ""

# Function to clean old files
clean_old_files() {
    local dir=$1
    local pattern=$2
    local count=0
    
    if [ ! -d "$dir" ]; then
        return
    fi
    
    echo -e "${GREEN}Cleaning $dir...${NC}"
    
    while IFS= read -r -d '' file; do
        if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}Would delete:${NC} $file"
        else
            if [ "$VERBOSE" = true ]; then
                echo -e "${GREEN}Deleting:${NC} $file"
            fi
            rm -f "$file"
        fi
        count=$((count + 1))
    done < <(find "$dir" -name "$pattern" -type f -mtime +${RETENTION_DAYS} -print0)
    
    if [ $count -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Processed $count files"
    else
        echo -e "  ${YELLOW}No old files found${NC}"
    fi
}

# Function to compress old logs
compress_old_logs() {
    local dir=$1
    local count=0
    
    if [ ! -d "$dir" ] || [ "$COMPRESS" = false ]; then
        return
    fi
    
    echo -e "${GREEN}Compressing old logs in $dir...${NC}"
    
    while IFS= read -r -d '' file; do
        if [[ ! "$file" =~ \.gz$ ]]; then
            if [ "$DRY_RUN" = true ]; then
                echo -e "${YELLOW}Would compress:${NC} $file"
            else
                if [ "$VERBOSE" = true ]; then
                    echo -e "${GREEN}Compressing:${NC} $file"
                fi
                gzip "$file"
            fi
            count=$((count + 1))
        fi
    done < <(find "$dir" -name "*.log" -type f -mtime +7 -print0)
    
    if [ $count -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} Compressed $count files"
    else
        echo -e "  ${YELLOW}No files to compress${NC}"
    fi
}

# Clean honeypot logs
echo -e "${GREEN}Cleaning honeypot logs...${NC}"
for honeypot in data/*/log; do
    if [ -d "$honeypot" ]; then
        clean_old_files "$honeypot" "*.log"
        clean_old_files "$honeypot" "*.json"
        compress_old_logs "$honeypot"
    fi
done
echo ""

# Clean Elasticsearch old indices (if accessible)
if curl -s http://localhost:64298/_cat/indices > /dev/null 2>&1; then
    echo -e "${GREEN}Checking Elasticsearch indices...${NC}"
    
    # Get indices older than retention period
    OLD_INDICES=$(curl -s "http://localhost:64298/_cat/indices?h=index,creation.date.string" | \
        awk -v days=$RETENTION_DAYS '
        {
            cmd = "date -d \"" $2 "\" +%s 2>/dev/null || date -j -f \"%Y-%m-%dT%H:%M:%S\" \"" $2 "\" +%s 2>/dev/null"
            cmd | getline timestamp
            close(cmd)
            
            cmd = "date +%s"
            cmd | getline now
            close(cmd)
            
            age_days = (now - timestamp) / 86400
            if (age_days > days) print $1
        }')
    
    if [ -n "$OLD_INDICES" ]; then
        echo "$OLD_INDICES" | while read -r index; do
            if [ "$DRY_RUN" = true ]; then
                echo -e "${YELLOW}Would delete index:${NC} $index"
            else
                if [ "$VERBOSE" = true ]; then
                    echo -e "${GREEN}Deleting index:${NC} $index"
                fi
                curl -s -X DELETE "http://localhost:64298/$index" > /dev/null
            fi
        done
    else
        echo -e "  ${YELLOW}No old indices found${NC}"
    fi
else
    echo -e "${YELLOW}Elasticsearch not accessible, skipping index cleanup${NC}"
fi
echo ""

# Calculate space after cleanup
if [ "$DRY_RUN" = false ]; then
    SPACE_AFTER=$(du -sh data | cut -f1)
    echo -e "${GREEN}=== Cleanup Complete ===${NC}"
    echo -e "Space before: ${YELLOW}${SPACE_BEFORE}${NC}"
    echo -e "Space after:  ${YELLOW}${SPACE_AFTER}${NC}"
else
    echo -e "${YELLOW}Dry run complete. No changes were made.${NC}"
    echo -e "Run without --dry-run to apply changes."
fi
echo ""
