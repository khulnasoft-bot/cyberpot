#!/bin/bash

# Helper script to set Elasticsearch heap size based on resource mode
# This is sourced by docker-compose to set ES_JAVA_OPTS dynamically

MODE=${CYBERPOT_RESOURCE_MODE:-STANDARD}

case $MODE in
    LOW)
        echo "-Xms1024m -Xmx1024m"
        ;;
    STANDARD)
        echo "-Xms2048m -Xmx2048m"
        ;;
    HIGH)
        echo "-Xms4096m -Xmx4096m"
        ;;
    *)
        echo "-Xms2048m -Xmx2048m"
        ;;
esac
