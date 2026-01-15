# CyberPot Resource Optimization Guide

## Overview

This guide explains how to optimize CyberPot's resource usage for different deployment scenarios. CyberPot supports three resource modes: **LOW**, **STANDARD**, and **HIGH**, each optimized for specific hardware constraints and performance requirements.

## Resource Modes

### LOW Mode
**Recommended for:** Raspberry Pi, small VMs, resource-constrained environments

**Specifications:**
- Elasticsearch heap: 1GB
- Logstash heap: 512MB
- Kibana memory limit: 512MB
- Log retention: 14 days
- Map update interval: 5000ms (5 seconds)
- Reduced polling frequency
- Aggressive log cleanup

**Expected Performance:**
- Lower memory usage (~4-6GB total)
- Slightly delayed real-time updates
- Suitable for small-scale deployments

### STANDARD Mode (Default)
**Recommended for:** Most deployments, standard servers, typical use cases

**Specifications:**
- Elasticsearch heap: 2GB
- Logstash heap: 1GB
- Kibana memory limit: 1GB
- Log retention: 30 days
- Map update interval: 2000ms (2 seconds)
- Balanced polling frequency
- Standard log cleanup

**Expected Performance:**
- Balanced resource usage (~8-12GB total)
- Good real-time performance
- Suitable for most production deployments

### HIGH Mode
**Recommended for:** High-traffic environments, production servers, multiple sensors

**Specifications:**
- Elasticsearch heap: 4GB
- Logstash heap: 2GB
- Kibana memory limit: 2GB
- Log retention: 60 days
- Map update interval: 1000ms (1 second)
- Frequent polling
- Extended log retention

**Expected Performance:**
- Higher resource usage (~16-20GB total)
- Excellent real-time performance
- Suitable for high-load production environments

## Configuration

### Setting Resource Mode

Use the optimization script to set the resource mode:

```bash
# Set to LOW mode
./scripts/optimize-resources.sh --mode LOW

# Set to STANDARD mode (default)
./scripts/optimize-resources.sh --mode STANDARD

# Set to HIGH mode
./scripts/optimize-resources.sh --mode HIGH

# Preview changes without applying
./scripts/optimize-resources.sh --mode LOW --dry-run
```

### Manual Configuration

Edit `.env` file:

```bash
# Set resource mode
CYBERPOT_RESOURCE_MODE=STANDARD

# Override specific settings (optional)
CYBERPOT_LOG_RETENTION_DAYS=30
CYBERPOT_MAP_UPDATE_INTERVAL=2000
```

## Memory Optimization

### Elasticsearch

Elasticsearch is the primary memory consumer. Optimize with:

1. **Heap Size**: Set via `ES_JAVA_OPTS` in docker-compose.yml
   - Never exceed 50% of available RAM
   - Never exceed 32GB (compressed pointers limit)

2. **Index Lifecycle Management (ILM)**:
   ```bash
   # Apply ILM policy
   curl -X PUT "localhost:64298/_ilm/policy/cyberpot-policy" \
     -H 'Content-Type: application/json' \
     -d @docker/elk/elasticsearch/ilm-policy.json
   ```

3. **Shard Optimization**:
   - LOW mode: 1 primary shard, 0 replicas
   - STANDARD mode: 1 primary shard, 0 replicas
   - HIGH mode: 2 primary shards, 1 replica

### Logstash

Optimize Logstash memory:

1. **Heap Size**: Set via `LS_JAVA_OPTS`
2. **Pipeline Workers**: Adjust based on CPU cores
3. **Batch Size**: Larger batches = better throughput, more memory

### Backend & Dashboard

1. **Caching**: Responses are cached (default: 60s TTL)
2. **Batching**: Events are batched before processing
3. **Incremental Updates**: Only changes are transmitted

## Disk Space Management

### Log Rotation

Automatic log rotation is configured via logrotate:

```bash
# Manual rotation
logrotate -f docker/elk/logstash/logrotate.conf

# Check rotation status
logrotate -d docker/elk/logstash/logrotate.conf
```

### Cleanup Old Data

Use the cleanup script:

```bash
# Clean logs older than 30 days
./scripts/cleanup-old-data.sh

# Clean logs older than 14 days
./scripts/cleanup-old-data.sh --days 14

# Preview what would be deleted
./scripts/cleanup-old-data.sh --dry-run

# Verbose output
./scripts/cleanup-old-data.sh --verbose
```

### Elasticsearch Index Management

Indices are automatically managed via ILM:

- **Hot phase** (0-7 days): Actively written, searchable
- **Warm phase** (7-30 days): Read-only, compressed, shrunk
- **Delete phase** (30+ days): Automatically deleted

Manual index cleanup:

```bash
# List all indices
curl "localhost:64298/_cat/indices?v"

# Delete specific index
curl -X DELETE "localhost:64298/index-name"

# Delete indices older than 30 days
curl -s "localhost:64298/_cat/indices?h=index,creation.date" | \
  awk '{if ($2 < (systime() - 30*86400)) print $1}' | \
  xargs -I {} curl -X DELETE "localhost:64298/{}"
```

## Monitoring

### Real-Time Monitoring

Use the monitoring script:

```bash
# Continuous monitoring
./scripts/monitor-resources.sh

# Monitor for 5 minutes
./scripts/monitor-resources.sh --duration 300

# Update every 10 seconds
./scripts/monitor-resources.sh --interval 10
```

### Metrics Endpoints

- **Backend Health**: `http://localhost:3000/health`
- **Prometheus Metrics**: `http://localhost:3000/metrics`
- **Elasticsearch Health**: `http://localhost:64298/_cluster/health`

### Grafana Dashboards

Access Grafana at `https://<your-ip>:64297/grafana` (if configured)

## Performance Tuning

### Network Optimization

1. **WebSocket Connections**: Limited based on resource mode
2. **Data Compression**: Enabled for large payloads
3. **Incremental Updates**: Only changes are transmitted

### Query Optimization

1. **Caching**: Frequently accessed data is cached
2. **Pagination**: Large result sets are paginated
3. **Field Filtering**: Only required fields are returned

### Container Resources

Adjust in `docker-compose.yml`:

```yaml
elasticsearch:
  mem_limit: 4g  # Adjust based on mode
  ulimits:
    memlock:
      soft: -1
      hard: -1
```

## Troubleshooting

### High Memory Usage

1. Check current usage:
   ```bash
   docker stats
   free -h
   ```

2. Reduce Elasticsearch heap:
   ```bash
   # Edit .env
   CYBERPOT_RESOURCE_MODE=LOW
   ```

3. Clear cache:
   ```bash
   curl -X POST "localhost:64298/_cache/clear"
   ```

### Disk Space Full

1. Check usage:
   ```bash
   df -h ~/cyberpot/data
   du -sh ~/cyberpot/data/*
   ```

2. Run cleanup:
   ```bash
   ./scripts/cleanup-old-data.sh
   ```

3. Reduce retention:
   ```bash
   # Edit .env
   CYBERPOT_LOG_RETENTION_DAYS=14
   ```

### Slow Performance

1. Check resource mode:
   ```bash
   grep CYBERPOT_RESOURCE_MODE .env
   ```

2. Increase resources:
   ```bash
   ./scripts/optimize-resources.sh --mode HIGH
   ```

3. Check Elasticsearch health:
   ```bash
   curl "localhost:64298/_cluster/health?pretty"
   ```

## Best Practices

1. **Start with STANDARD mode** and adjust based on actual usage
2. **Monitor regularly** using the monitoring script
3. **Clean up old data** periodically
4. **Review logs** for errors and warnings
5. **Adjust retention** based on compliance requirements
6. **Use ILM policies** for automatic index management
7. **Enable compression** for log files
8. **Set up alerts** for resource thresholds

## Advanced Configuration

### Custom Resource Limits

Edit `resource_config.env` for fine-grained control:

```bash
# Custom memory limits
CYBERPOT_ES_HEAP_SIZE_CUSTOM=3072m
CYBERPOT_LS_HEAP_SIZE_CUSTOM=1536m

# Custom retention
CYBERPOT_LOG_RETENTION_DAYS_CUSTOM=45

# Custom update intervals
CYBERPOT_MAP_UPDATE_INTERVAL_CUSTOM=1500
```

### Horizontal Scaling

For very high loads, consider:

1. **Multiple Elasticsearch nodes**
2. **Logstash pipeline workers**
3. **Load-balanced backend instances**
4. **Distributed sensors**

## Support

For issues or questions:
- Check logs: `docker logs <container-name>`
- Review metrics: `./scripts/monitor-resources.sh`
- Open an issue on GitHub with resource usage details

---

**Last Updated**: 2026-01-15  
**Version**: 1.0.0
