#!/bin/bash

# CyberPot Performance Testing Script
# Run load tests and detect regressions

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Default values
COMPARE_BASELINE=false
GENERATE_REPORT=false
BASE_URL="http://localhost:3000"
OUTPUT_DIR="tests/performance/results"

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run CyberPot performance tests.

OPTIONS:
    -c, --compare-baseline    Compare results against baseline
    -r, --report              Generate HTML report
    -u, --url URL             Base URL to test (default: http://localhost:3000)
    -o, --output DIR          Output directory (default: tests/performance/results)
    -h, --help                Show this help message

EXAMPLES:
    $0                        # Run performance tests
    $0 --compare-baseline     # Run and compare against baseline
    $0 --report               # Run and generate HTML report

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--compare-baseline)
            COMPARE_BASELINE=true
            shift
            ;;
        -r|--report)
            GENERATE_REPORT=true
            shift
            ;;
        -u|--url)
            BASE_URL="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
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

echo -e "${GREEN}=== CyberPot Performance Testing ===${NC}"
echo -e "Base URL: ${YELLOW}$BASE_URL${NC}"
echo ""

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo -e "${RED}Error: k6 is not installed${NC}"
    echo -e "Install k6: https://k6.io/docs/getting-started/installation/"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run load test
echo -e "${GREEN}Running load tests...${NC}"
k6 run \
    --out json="$OUTPUT_DIR/performance-results.json" \
    -e BASE_URL="$BASE_URL" \
    tests/performance/load-test.js

echo -e "${GREEN}✓ Load tests complete${NC}"
echo ""

# Compare against baseline
if [ "$COMPARE_BASELINE" = true ]; then
    echo -e "${GREEN}Comparing against baseline...${NC}"
    
    if [ ! -f "tests/performance/baseline.json" ]; then
        echo -e "${YELLOW}Warning: baseline.json not found, skipping comparison${NC}"
    else
        node tests/performance/regression-detector.js \
            "$OUTPUT_DIR/performance-results.json" \
            "tests/performance/baseline.json"
    fi
    echo ""
fi

# Generate HTML report
if [ "$GENERATE_REPORT" = true ]; then
    echo -e "${GREEN}Generating HTML report...${NC}"
    k6 run \
        --out html="$OUTPUT_DIR/performance-report.html" \
        -e BASE_URL="$BASE_URL" \
        tests/performance/load-test.js
    echo -e "${GREEN}✓ Report generated: $OUTPUT_DIR/performance-report.html${NC}"
    echo ""
fi

echo -e "${GREEN}=== Performance Testing Complete ===${NC}"
echo -e "Results: ${YELLOW}$OUTPUT_DIR/performance-results.json${NC}"

# Show summary
if [ -f "$OUTPUT_DIR/performance-results.json" ]; then
    echo ""
    echo -e "${GREEN}Summary:${NC}"
    cat "$OUTPUT_DIR/performance-results.json" | jq '.metrics | {
        "Requests": .http_reqs.values.count,
        "Failed": .http_req_failed.values.rate,
        "Avg Duration": .http_req_duration.values.avg,
        "P95 Duration": .http_req_duration.values["p(95)"],
        "P99 Duration": .http_req_duration.values["p(99)"]
    }'
fi
