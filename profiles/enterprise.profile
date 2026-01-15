# CyberPot Resource Profile: Enterprise Production
# Optimized for high-performance production deployments

# Resource Mode
CYBERPOT_RESOURCE_MODE=HIGH

# Memory Configuration
CYBERPOT_ES_HEAP_SIZE=-Xms4096m -Xmx4096m
CYBERPOT_LS_HEAP_SIZE=-Xms2048m -Xmx2048m
CYBERPOT_ES_MEM_LIMIT=8g
CYBERPOT_KIBANA_MEM_LIMIT=2g
CYBERPOT_LS_MEM_LIMIT=4g

# Disk Configuration
CYBERPOT_LOG_RETENTION_DAYS=90
CYBERPOT_LOG_MAX_SIZE_MB=200

# Performance Configuration
CYBERPOT_MAP_UPDATE_INTERVAL=500
CYBERPOT_CACHE_TTL=30
CYBERPOT_BATCH_SIZE=25

# Monitoring
CYBERPOT_MONITORING_ENABLED=true

# Elasticsearch Configuration
CYBERPOT_ES_SHARDS=2
CYBERPOT_ES_REPLICAS=1

# Logstash Configuration
CYBERPOT_LS_WORKERS=8
CYBERPOT_LS_BATCH_SIZE=50

# Scaling Configuration
CYBERPOT_ENABLE_SCALING=true
CYBERPOT_BACKEND_INSTANCES=3

# Profile Metadata
PROFILE_NAME="Enterprise Production"
PROFILE_DESCRIPTION="High-performance configuration for production environments"
PROFILE_MIN_RAM_GB=16
PROFILE_MIN_DISK_GB=500
