/**
 * Resource Monitoring Utility
 * Tracks memory usage, event processing rates, and exposes metrics
 */

interface ResourceMetrics {
    memory: {
        heapUsed: number;
        heapTotal: number;
        rss: number;
        external: number;
        heapUsedPercent: number;
    };
    process: {
        uptime: number;
        cpu: number;
    };
    events: {
        processed: number;
        rate: number;
        errors: number;
    };
    timestamp: number;
}

interface AlertThresholds {
    memoryPercent: number;
    cpuPercent: number;
    errorRate: number;
}

class ResourceMonitor {
    private metrics: ResourceMetrics;
    private eventCounter: number = 0;
    private errorCounter: number = 0;
    private lastCheckTime: number = Date.now();
    private thresholds: AlertThresholds;
    private alertCallbacks: Array<(metric: string, value: number) => void> = [];

    constructor(thresholds?: Partial<AlertThresholds>) {
        this.thresholds = {
            memoryPercent: thresholds?.memoryPercent || 90,
            cpuPercent: thresholds?.cpuPercent || 80,
            errorRate: thresholds?.errorRate || 0.05, // 5% error rate
        };

        this.metrics = this.collectMetrics();

        // Update metrics every 15 seconds
        setInterval(() => {
            this.metrics = this.collectMetrics();
            this.checkThresholds();
        }, 15000);
    }

    /**
     * Collect current resource metrics
     */
    private collectMetrics(): ResourceMetrics {
        const memUsage = process.memoryUsage();
        const now = Date.now();
        const timeDiff = (now - this.lastCheckTime) / 1000; // seconds
        const eventRate = timeDiff > 0 ? this.eventCounter / timeDiff : 0;

        const heapUsedPercent = (memUsage.heapUsed / memUsage.heapTotal) * 100;

        return {
            memory: {
                heapUsed: memUsage.heapUsed,
                heapTotal: memUsage.heapTotal,
                rss: memUsage.rss,
                external: memUsage.external,
                heapUsedPercent,
            },
            process: {
                uptime: process.uptime(),
                cpu: process.cpuUsage().user / 1000000, // Convert to seconds
            },
            events: {
                processed: this.eventCounter,
                rate: eventRate,
                errors: this.errorCounter,
            },
            timestamp: now,
        };
    }

    /**
     * Check if any metrics exceed thresholds and trigger alerts
     */
    private checkThresholds(): void {
        const { memory, events } = this.metrics;

        // Check memory threshold
        if (memory.heapUsedPercent > this.thresholds.memoryPercent) {
            this.triggerAlert('memory', memory.heapUsedPercent);
        }

        // Check error rate threshold
        const errorRate = events.processed > 0 ? events.errors / events.processed : 0;
        if (errorRate > this.thresholds.errorRate) {
            this.triggerAlert('errorRate', errorRate * 100);
        }
    }

    /**
     * Trigger alert callbacks
     */
    private triggerAlert(metric: string, value: number): void {
        console.warn(`[ResourceMonitor] Alert: ${metric} = ${value.toFixed(2)}`);
        this.alertCallbacks.forEach(callback => callback(metric, value));
    }

    /**
     * Register alert callback
     */
    public onAlert(callback: (metric: string, value: number) => void): void {
        this.alertCallbacks.push(callback);
    }

    /**
     * Increment event counter (call when processing an event)
     */
    public recordEvent(): void {
        this.eventCounter++;
    }

    /**
     * Increment error counter (call when an error occurs)
     */
    public recordError(): void {
        this.errorCounter++;
    }

    /**
     * Get current metrics
     */
    public getMetrics(): ResourceMetrics {
        return { ...this.metrics };
    }

    /**
     * Get metrics in Prometheus format
     */
    public getPrometheusMetrics(): string {
        const m = this.metrics;
        return `
# HELP cyberpot_memory_heap_used_bytes Heap memory used in bytes
# TYPE cyberpot_memory_heap_used_bytes gauge
cyberpot_memory_heap_used_bytes ${m.memory.heapUsed}

# HELP cyberpot_memory_heap_total_bytes Total heap memory in bytes
# TYPE cyberpot_memory_heap_total_bytes gauge
cyberpot_memory_heap_total_bytes ${m.memory.heapTotal}

# HELP cyberpot_memory_rss_bytes Resident set size in bytes
# TYPE cyberpot_memory_rss_bytes gauge
cyberpot_memory_rss_bytes ${m.memory.rss}

# HELP cyberpot_memory_heap_percent Heap usage percentage
# TYPE cyberpot_memory_heap_percent gauge
cyberpot_memory_heap_percent ${m.memory.heapUsedPercent.toFixed(2)}

# HELP cyberpot_process_uptime_seconds Process uptime in seconds
# TYPE cyberpot_process_uptime_seconds counter
cyberpot_process_uptime_seconds ${m.process.uptime}

# HELP cyberpot_events_processed_total Total events processed
# TYPE cyberpot_events_processed_total counter
cyberpot_events_processed_total ${m.events.processed}

# HELP cyberpot_events_rate Events processed per second
# TYPE cyberpot_events_rate gauge
cyberpot_events_rate ${m.events.rate.toFixed(2)}

# HELP cyberpot_events_errors_total Total event processing errors
# TYPE cyberpot_events_errors_total counter
cyberpot_events_errors_total ${m.events.errors}
`.trim();
    }

    /**
     * Reset counters (useful for testing)
     */
    public reset(): void {
        this.eventCounter = 0;
        this.errorCounter = 0;
        this.lastCheckTime = Date.now();
    }

    /**
     * Get memory usage summary
     */
    public getMemorySummary(): string {
        const m = this.metrics.memory;
        return `Memory: ${(m.heapUsed / 1024 / 1024).toFixed(2)}MB / ${(m.heapTotal / 1024 / 1024).toFixed(2)}MB (${m.heapUsedPercent.toFixed(1)}%)`;
    }
}

// Singleton instance
let monitorInstance: ResourceMonitor | null = null;

/**
 * Get or create the resource monitor instance
 */
export function getResourceMonitor(thresholds?: Partial<AlertThresholds>): ResourceMonitor {
    if (!monitorInstance) {
        monitorInstance = new ResourceMonitor(thresholds);
    }
    return monitorInstance;
}

export default ResourceMonitor;
