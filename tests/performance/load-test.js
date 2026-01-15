import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const apiLatency = new Trend('api_latency');

// Test configuration
export const options = {
    stages: [
        { duration: '30s', target: 10 },   // Ramp up to 10 users
        { duration: '1m', target: 50 },    // Ramp up to 50 users
        { duration: '2m', target: 50 },    // Stay at 50 users
        { duration: '30s', target: 100 },  // Spike to 100 users
        { duration: '1m', target: 100 },   // Stay at 100 users
        { duration: '30s', target: 0 },    // Ramp down
    ],
    thresholds: {
        http_req_duration: ['p(95)<500', 'p(99)<1000'], // 95% < 500ms, 99% < 1s
        http_req_failed: ['rate<0.01'],                  // Error rate < 1%
        errors: ['rate<0.05'],                           // Custom error rate < 5%
    },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export default function () {
    // Test health endpoint
    let healthRes = http.get(`${BASE_URL}/health`);
    check(healthRes, {
        'health check status 200': (r) => r.status === 200,
        'health check has status': (r) => r.json('status') !== undefined,
    }) || errorRate.add(1);
    apiLatency.add(healthRes.timings.duration);

    sleep(0.5);

    // Test sensors endpoint
    let sensorsRes = http.get(`${BASE_URL}/api/sensors`);
    check(sensorsRes, {
        'sensors status 200': (r) => r.status === 200,
        'sensors returns array': (r) => Array.isArray(r.json()),
    }) || errorRate.add(1);
    apiLatency.add(sensorsRes.timings.duration);

    sleep(0.5);

    // Test geodata endpoint
    let geodataRes = http.get(`${BASE_URL}/api/geodata`);
    check(geodataRes, {
        'geodata status 200': (r) => r.status === 200,
        'geodata returns array': (r) => Array.isArray(r.json()),
    }) || errorRate.add(1);
    apiLatency.add(geodataRes.timings.duration);

    sleep(0.5);

    // Test containers endpoint
    let containersRes = http.get(`${BASE_URL}/api/containers`);
    check(containersRes, {
        'containers status 200': (r) => r.status === 200,
    }) || errorRate.add(1);
    apiLatency.add(containersRes.timings.duration);

    sleep(1);

    // Test analyze endpoint
    let analyzeRes = http.post(
        `${BASE_URL}/api/analyze`,
        JSON.stringify({ log: 'ssh brute force attempt' }),
        { headers: { 'Content-Type': 'application/json' } }
    );
    check(analyzeRes, {
        'analyze status 200': (r) => r.status === 200,
        'analyze returns analysis': (r) => r.json('analysis') !== undefined,
    }) || errorRate.add(1);
    apiLatency.add(analyzeRes.timings.duration);

    sleep(1);
}

export function handleSummary(data) {
    return {
        'performance-results.json': JSON.stringify(data, null, 2),
        stdout: textSummary(data, { indent: ' ', enableColors: true }),
    };
}

function textSummary(data, options) {
    const indent = options.indent || '';
    const enableColors = options.enableColors || false;

    let summary = `\n${indent}Performance Test Summary\n${indent}========================\n\n`;

    // Add metrics
    for (const [name, metric] of Object.entries(data.metrics)) {
        if (metric.values) {
            summary += `${indent}${name}:\n`;
            for (const [key, value] of Object.entries(metric.values)) {
                summary += `${indent}  ${key}: ${value}\n`;
            }
        }
    }

    return summary;
}
