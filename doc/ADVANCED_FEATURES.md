# CyberPot Advanced Features Documentation

## Overview

This guide covers advanced features for production-grade CyberPot deployments including Prometheus/Grafana monitoring, horizontal scaling, performance testing, and custom resource profiles.

---

## Prometheus/Grafana Monitoring

### Quick Start

```bash
# Start monitoring stack
docker-compose -f docker-compose.monitoring.yml up -d

# Access Grafana
open http://localhost:3001
# Default credentials: admin/admin
```

### Components

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Node Exporter**: System metrics (CPU, memory, disk)
- **cAdvisor**: Container metrics
- **Alertmanager**: Alert routing and notifications

### Dashboards

1. **Resource Usage** (`http://localhost:3001/d/resources`)
   - Memory usage by container
   - CPU usage trends
   - Disk space monitoring
   - Network I/O

2. **Attack Analytics** (custom)
   - Attack patterns over time
   - Geographic distribution
   - Honeypot activity

3. **System Health** (custom)
   - Elasticsearch cluster health
   - Container status
   - Active alerts

### Configuration

Edit `docker/prometheus/prometheus.yml` to add scrape targets:

```yaml
scrape_configs:
  - job_name: 'my-service'
    static_configs:
      - targets: ['my-service:9090']
```

Edit `docker/alertmanager/config.yml` for notifications:

```yaml
receivers:
  - name: 'slack'
    slack_configs:
      - api_url: 'YOUR_WEBHOOK_URL'
        channel: '#alerts'
```

---

## Horizontal Scaling

### Architecture

```
Internet → HAProxy → Backend Instance 1
                  → Backend Instance 2
                  → Backend Instance 3
                         ↓
                      Redis (shared state)
```

### Quick Start

```bash
# Scale to 3 backend instances
./scripts/scale-backend.sh --instances 3

# Check status
./scripts/scale-backend.sh --action status

# View HAProxy stats
open http://localhost:8404/stats
```

### Configuration

**Load Balancer**: HAProxy with round-robin balancing
**Session Store**: Redis for shared sessions
**Health Checks**: Automatic health monitoring

### Auto-Scaling (Manual)

Monitor metrics and scale based on load:

```bash
# If CPU > 80%, scale up
./scripts/scale-backend.sh --instances 5

# If CPU < 30%, scale down
./scripts/scale-backend.sh --instances 2
```

---

## Performance Testing

### Prerequisites

Install k6:
```bash
# macOS
brew install k6

# Linux
sudo apt-get install k6
```

### Running Tests

```bash
# Basic load test
./scripts/run-performance-tests.sh

# Compare against baseline
./scripts/run-performance-tests.sh --compare-baseline

# Generate HTML report
./scripts/run-performance-tests.sh --report
```

### Test Scenarios

The load test simulates:
- 30s ramp-up to 10 users
- 1m ramp-up to 50 users
- 2m sustained load at 50 users
- 30s spike to 100 users
- 1m sustained at 100 users
- 30s ramp-down

### Performance Thresholds

| Metric | Threshold |
|--------|-----------|
| P95 Response Time | < 500ms |
| P99 Response Time | < 1000ms |
| Error Rate | < 1% |
| Custom Error Rate | < 5% |

### Baseline Management

Update baseline after improvements:

```bash
# Run test and save as new baseline
./scripts/run-performance-tests.sh
cp tests/performance/results/performance-results.json tests/performance/baseline.json
```

---

## Custom Resource Profiles

### Available Profiles

1. **raspberry-pi**: Optimized for Raspberry Pi 4/5
   - 4-8GB RAM
   - Minimal resource usage
   - 7-day log retention

2. **cloud-small**: Cloud micro/small instances
   - 4-8GB RAM
   - Balanced performance
   - 14-day log retention

3. **enterprise**: High-performance production
   - 16+ GB RAM
   - Maximum performance
   - 90-day log retention
   - Scaling enabled

### Using Profiles

```bash
# List available profiles
./scripts/apply-profile.sh --action list

# Apply a profile
./scripts/apply-profile.sh raspberry-pi

# Create custom profile
./scripts/apply-profile.sh --action create my-custom

# Validate profile
./scripts/apply-profile.sh --action validate my-custom
```

### Profile Structure

```bash
# Resource Mode
CYBERPOT_RESOURCE_MODE=STANDARD

# Memory Configuration
CYBERPOT_ES_HEAP_SIZE=-Xms2048m -Xmx2048m
CYBERPOT_LS_HEAP_SIZE=-Xms1024m -Xmx1024m

# Disk Configuration
CYBERPOT_LOG_RETENTION_DAYS=30

# Performance Configuration
CYBERPOT_MAP_UPDATE_INTERVAL=2000

# Profile Metadata
PROFILE_NAME="My Profile"
PROFILE_DESCRIPTION="Custom configuration"
PROFILE_MIN_RAM_GB=8
PROFILE_MIN_DISK_GB=128
```

---

## CI/CD Integration

### GitHub Actions

Performance tests can run automatically on PRs:

```yaml
name: Performance Tests
on: [pull_request]
jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run tests
        run: ./scripts/run-performance-tests.sh --compare-baseline
```

---

## Troubleshooting

### Monitoring Stack

**Grafana not accessible:**
```bash
docker logs cyberpot_grafana
docker-compose -f docker-compose.monitoring.yml restart grafana
```

**Prometheus not scraping:**
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets
```

### Scaling

**Backend instances not starting:**
```bash
docker-compose -f docker-compose.scale.yml logs backend
```

**HAProxy not load balancing:**
```bash
# Check HAProxy stats
curl http://localhost:8404/stats
```

### Performance Testing

**k6 tests failing:**
```bash
# Check backend is running
curl http://localhost:3000/health

# Run with verbose output
k6 run --verbose tests/performance/load-test.js
```

---

## Best Practices

1. **Monitoring**
   - Set up alert notifications (Slack, email)
   - Review dashboards regularly
   - Adjust thresholds based on your environment

2. **Scaling**
   - Start with 1 instance, scale as needed
   - Monitor Redis memory usage
   - Use auto-scaling in production

3. **Performance Testing**
   - Run tests before major releases
   - Update baselines after optimizations
   - Test under realistic load

4. **Profiles**
   - Choose profile matching your hardware
   - Create custom profiles for specific needs
   - Document profile changes

---

## Support

For issues or questions:
- Check logs: `docker logs <container-name>`
- Review metrics: `http://localhost:3001`
- Open GitHub issue with details

---

**Last Updated**: 2026-01-15  
**Version**: 2.0.0
