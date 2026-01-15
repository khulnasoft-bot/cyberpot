import { useState, useEffect } from 'react';

interface ResourceMode {
    mode: 'LOW' | 'STANDARD' | 'HIGH';
    updateInterval: number;
    cacheTTL: number;
}

/**
 * Hook to detect and adapt to the current resource mode
 */
export function useResourceMode() {
    const [resourceMode, setResourceMode] = useState<ResourceMode>({
        mode: 'STANDARD',
        updateInterval: 2000,
        cacheTTL: 60,
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Fetch resource mode from backend
        fetch('http://localhost:3000/api/config/resource-mode')
            .then(res => res.json())
            .then(data => {
                setResourceMode(data);
                setLoading(false);
            })
            .catch(err => {
                console.error('Failed to fetch resource mode:', err);
                setLoading(false);
            });
    }, []);

    return { resourceMode, loading };
}

/**
 * Hook for adaptive polling based on resource mode
 */
export function useAdaptivePolling<T>(
    fetchFn: () => Promise<T>,
    defaultInterval: number = 2000
) {
    const { resourceMode } = useResourceMode();
    const [data, setData] = useState<T | null>(null);
    const [error, setError] = useState<Error | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        let mounted = true;
        let timeoutId: ReturnType<typeof setTimeout>;

        const poll = async () => {
            try {
                const result = await fetchFn();
                if (mounted) {
                    setData(result);
                    setError(null);
                    setLoading(false);
                }
            } catch (err) {
                if (mounted) {
                    setError(err as Error);
                    setLoading(false);
                }
            }

            if (mounted) {
                const interval = resourceMode.updateInterval || defaultInterval;
                timeoutId = setTimeout(poll, interval);
            }
        };

        poll();

        return () => {
            mounted = false;
            if (timeoutId) {
                clearTimeout(timeoutId);
            }
        };
    }, [fetchFn, resourceMode.updateInterval, defaultInterval]);

    return { data, error, loading };
}

/**
 * Hook for throttled updates based on resource mode
 */
export function useThrottledCallback<T extends (...args: any[]) => void>(
    callback: T,
    delay?: number
): T {
    const { resourceMode } = useResourceMode();
    const [throttledFn] = useState(() => {
        let lastCall = 0;
        let timeout: ReturnType<typeof setTimeout> | null = null;

        return function (this: any, ...args: Parameters<T>) {
            const actualDelay = delay || resourceMode.updateInterval || 2000;
            const now = Date.now();
            const timeSinceLastCall = now - lastCall;

            if (timeSinceLastCall >= actualDelay) {
                lastCall = now;
                callback.apply(this, args);
            } else if (!timeout) {
                timeout = setTimeout(() => {
                    lastCall = Date.now();
                    timeout = null;
                    callback.apply(this, args);
                }, actualDelay - timeSinceLastCall);
            }
        } as T;
    });

    return throttledFn;
}

/**
 * Hook to determine if features should be enabled based on resource mode
 */
export function useFeatureFlags() {
    const { resourceMode } = useResourceMode();

    return {
        enableAnimations: resourceMode.mode !== 'LOW',
        enableRealTimeUpdates: resourceMode.mode !== 'LOW',
        enableDetailedMetrics: resourceMode.mode === 'HIGH',
        maxVisibleItems: resourceMode.mode === 'LOW' ? 10 : resourceMode.mode === 'STANDARD' ? 50 : 100,
        updateInterval: resourceMode.updateInterval,
    };
}

export default useResourceMode;
