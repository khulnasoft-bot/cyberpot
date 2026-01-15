import express from 'express';
import cors from 'cors';
import Docker from 'dockerode';
import { getResourceMonitor } from './utils/resourceMonitor';
import { EventBatcher, calculateDiff, throttle } from './utils/dataOptimizer';

const app = express();
const port = process.env.PORT || 3000;
const docker = new Docker({ socketPath: '/var/run/docker.sock' });

// Initialize resource monitor
const resourceMonitor = getResourceMonitor({
    memoryPercent: parseInt(process.env.CYBERPOT_ALERT_MEMORY_THRESHOLD || '90'),
    cpuPercent: 80,
    errorRate: 0.05,
});

// Set up alert logging
resourceMonitor.onAlert((metric, value) => {
    console.warn(`[ALERT] ${metric} threshold exceeded: ${value.toFixed(2)}`);
});

// Simple in-memory cache
interface CacheEntry<T> {
    data: T;
    timestamp: number;
}

const cache = new Map<string, CacheEntry<any>>();
const CACHE_TTL = parseInt(process.env.CYBERPOT_CACHE_TTL || '60') * 1000; // Convert to ms

function getCached<T>(key: string): T | null {
    const entry = cache.get(key);
    if (entry && Date.now() - entry.timestamp < CACHE_TTL) {
        return entry.data;
    }
    cache.delete(key);
    return null;
}

function setCache<T>(key: string, data: T): void {
    cache.set(key, { data, timestamp: Date.now() });
}

// Clean cache periodically
setInterval(() => {
    const now = Date.now();
    for (const [key, entry] of cache.entries()) {
        if (now - entry.timestamp > CACHE_TTL) {
            cache.delete(key);
        }
    }
}, 60000); // Clean every minute

app.use(cors());
app.use(express.json());

const sensors = [
    { id: '1', name: 'Pi-Sensor-01', status: 'online', ip: '192.168.1.101', lastSeen: 'Now' },
    { id: '2', name: 'Pi-Sensor-02', status: 'offline', ip: '192.168.1.102', lastSeen: '2h ago' },
    { id: '3', name: 'Cloud-Sensor-01', status: 'compromised', ip: '203.0.113.5', lastSeen: '5m ago' },
];

app.get('/api/sensors', (req, res) => {
    resourceMonitor.recordEvent();
    console.log('GET /api/sensors');

    // Check cache first
    const cached = getCached<typeof sensors>('sensors');
    if (cached) {
        return res.json(cached);
    }

    // Cache the response
    setCache('sensors', sensors);
    res.json(sensors);
});

app.get('/api/containers', async (req, res) => {
    resourceMonitor.recordEvent();
    console.log('GET /api/containers');

    try {
        // Check cache first
        const cached = getCached<any[]>('containers');
        if (cached) {
            return res.json(cached);
        }

        const containers = await docker.listContainers({ all: true });
        setCache('containers', containers);
        res.json(containers);
    } catch (err) {
        resourceMonitor.recordError();
        console.error('Error listing containers:', err);
        res.status(500).json({ error: 'Failed to list containers' });
    }
});

// Store previous geodata for diff calculation
let previousGeodata: any[] = [];

app.get('/api/geodata', (req, res) => {
    resourceMonitor.recordEvent();
    console.log('GET /api/geodata');

    const attacks = [
        { id: 1, lat: 55.75, lng: 37.61, city: 'Moscow', country: 'RU', type: 'SSH Brute Force', color: '#f87171' },
        { id: 2, lat: 39.90, lng: 116.40, city: 'Beijing', country: 'CN', type: 'Log4j Attempt', color: '#f87171' },
        { id: 3, lat: 50.45, lng: 30.52, city: 'Kyiv', country: 'UA', type: 'Telnet Access', color: '#f87171' },
        { id: 4, lat: 34.05, lng: -118.24, city: 'Los Angeles', country: 'US', type: 'SQL Injection', color: '#6366f1' },
        { id: 5, lat: 51.50, lng: -0.12, city: 'London', country: 'GB', type: 'DDoS Stream', color: '#6366f1' },
        { id: 6, lat: 35.67, lng: 139.65, city: 'Tokyo', country: 'JP', type: 'Scanner', color: '#10b981' },
    ];

    // Support incremental updates via query param
    if (req.query.incremental === 'true' && previousGeodata.length > 0) {
        const diff = calculateDiff(previousGeodata, attacks);
        previousGeodata = attacks;
        return res.json({ incremental: true, diff });
    }

    previousGeodata = attacks;
    res.json(attacks);
});

app.post('/api/analyze', async (req, res) => {
    resourceMonitor.recordEvent();
    const { log } = req.body;
    console.log('POST /api/analyze', log);

    try {
        // Simulated AI Logic
        const analyses: Record<string, string> = {
            'ssh': 'Initial access attempt via SSH brute force. The adversary is cycling through common credentials to gain a shell.',
            'log4j': 'Suspicious JNDI string detected. This indicates an attempt to exploit CVE-2021-44228 to gain remote code execution.',
            'telnet': 'Legacy protocol access detected. Common for Mirai-style IoT botnets looking for default admin credentials.',
            'sql': 'In-band SQL injection attempt. The attacker is trying to enumerate database schema via error-based techniques.',
            'scanner': 'Passive reconnaissance. An automated tool is mapping port availability and service versions.',
        };

        const type = log.toLowerCase();
        const result = Object.entries(analyses).find(([key]) => type.includes(key))?.[1]
            || 'Anomalous traffic pattern detected. Recommend immediate isolation and further package inspection.';

        // Simulate async processing
        await new Promise(resolve => setTimeout(resolve, 800));
        res.json({ analysis: result });
    } catch (err) {
        resourceMonitor.recordError();
        console.error('Error analyzing log:', err);
        res.status(500).json({ error: 'Analysis failed' });
    }
});

// Metrics endpoint for Prometheus
app.get('/metrics', (req, res) => {
    res.set('Content-Type', 'text/plain');
    res.send(resourceMonitor.getPrometheusMetrics());
});

// Health check endpoint
app.get('/health', (req, res) => {
    const metrics = resourceMonitor.getMetrics();
    const healthy = metrics.memory.heapUsedPercent < 95;

    res.status(healthy ? 200 : 503).json({
        status: healthy ? 'healthy' : 'unhealthy',
        memory: resourceMonitor.getMemorySummary(),
        uptime: metrics.process.uptime,
        eventsProcessed: metrics.events.processed,
        eventRate: metrics.events.rate.toFixed(2),
    });
});

// Resource mode endpoint
app.get('/api/config/resource-mode', (req, res) => {
    res.json({
        mode: process.env.CYBERPOT_RESOURCE_MODE || 'STANDARD',
        updateInterval: parseInt(process.env.CYBERPOT_MAP_UPDATE_INTERVAL || '2000'),
        cacheTTL: CACHE_TTL / 1000, // Convert back to seconds
    });
});

app.listen(port, () => {
    console.log(`Backend listening at http://localhost:${port}`);
});
