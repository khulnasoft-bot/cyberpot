/**
 * Data Optimization Utility
 * Provides batching, compression, and incremental update capabilities
 */

interface BatchConfig {
    maxSize: number;
    maxWaitMs: number;
}

interface DataDiff<T> {
    added: T[];
    removed: T[];
    updated: T[];
}

/**
 * Event Batcher - Collects events and processes them in batches
 */
export class EventBatcher<T> {
    private batch: T[] = [];
    private timer: NodeJS.Timeout | null = null;
    private config: BatchConfig;
    private processor: (batch: T[]) => Promise<void>;

    constructor(
        processor: (batch: T[]) => Promise<void>,
        config: Partial<BatchConfig> = {}
    ) {
        this.processor = processor;
        this.config = {
            maxSize: config.maxSize || 50,
            maxWaitMs: config.maxWaitMs || 1000,
        };
    }

    /**
     * Add event to batch
     */
    public add(event: T): void {
        this.batch.push(event);

        // Process immediately if batch is full
        if (this.batch.length >= this.config.maxSize) {
            this.flush();
        } else if (!this.timer) {
            // Start timer for partial batch
            this.timer = setTimeout(() => this.flush(), this.config.maxWaitMs);
        }
    }

    /**
     * Process current batch immediately
     */
    public async flush(): Promise<void> {
        if (this.timer) {
            clearTimeout(this.timer);
            this.timer = null;
        }

        if (this.batch.length === 0) {
            return;
        }

        const currentBatch = [...this.batch];
        this.batch = [];

        try {
            await this.processor(currentBatch);
        } catch (error) {
            console.error('[EventBatcher] Error processing batch:', error);
            // Optionally: implement retry logic or dead letter queue
        }
    }

    /**
     * Get current batch size
     */
    public size(): number {
        return this.batch.length;
    }
}

/**
 * Calculate incremental diff between two datasets
 */
export function calculateDiff<T extends { id: string | number }>(
    oldData: T[],
    newData: T[]
): DataDiff<T> {
    const oldMap = new Map(oldData.map(item => [item.id, item]));
    const newMap = new Map(newData.map(item => [item.id, item]));

    const added: T[] = [];
    const removed: T[] = [];
    const updated: T[] = [];

    // Find added and updated items
    for (const [id, newItem] of newMap) {
        const oldItem = oldMap.get(id);
        if (!oldItem) {
            added.push(newItem);
        } else if (JSON.stringify(oldItem) !== JSON.stringify(newItem)) {
            updated.push(newItem);
        }
    }

    // Find removed items
    for (const [id, oldItem] of oldMap) {
        if (!newMap.has(id)) {
            removed.push(oldItem);
        }
    }

    return { added, removed, updated };
}

/**
 * Compress data using simple run-length encoding for repeated values
 * Useful for time-series data with many repeated values
 */
export function compressData<T>(data: T[]): { compressed: any[]; size: number } {
    if (data.length === 0) {
        return { compressed: [], size: 0 };
    }

    const compressed: any[] = [];
    let current = data[0];
    let count = 1;

    for (let i = 1; i < data.length; i++) {
        if (JSON.stringify(data[i]) === JSON.stringify(current)) {
            count++;
        } else {
            compressed.push(count > 1 ? [current, count] : current);
            current = data[i];
            count = 1;
        }
    }
    compressed.push(count > 1 ? [current, count] : current);

    const originalSize = JSON.stringify(data).length;
    const compressedSize = JSON.stringify(compressed).length;

    return {
        compressed,
        size: compressedSize,
    };
}

/**
 * Decompress run-length encoded data
 */
export function decompressData<T>(compressed: any[]): T[] {
    const decompressed: T[] = [];

    for (const item of compressed) {
        if (Array.isArray(item) && item.length === 2) {
            // [value, count] format
            const [value, count] = item;
            for (let i = 0; i < count; i++) {
                decompressed.push(value);
            }
        } else {
            decompressed.push(item);
        }
    }

    return decompressed;
}

/**
 * Throttle function calls to reduce processing load
 */
export function throttle<T extends (...args: any[]) => any>(
    func: T,
    limitMs: number
): (...args: Parameters<T>) => void {
    let lastCall = 0;
    let timeout: NodeJS.Timeout | null = null;

    return function (this: any, ...args: Parameters<T>) {
        const now = Date.now();
        const timeSinceLastCall = now - lastCall;

        if (timeSinceLastCall >= limitMs) {
            lastCall = now;
            func.apply(this, args);
        } else if (!timeout) {
            timeout = setTimeout(() => {
                lastCall = Date.now();
                timeout = null;
                func.apply(this, args);
            }, limitMs - timeSinceLastCall);
        }
    };
}

/**
 * Debounce function calls to batch rapid updates
 */
export function debounce<T extends (...args: any[]) => any>(
    func: T,
    waitMs: number
): (...args: Parameters<T>) => void {
    let timeout: NodeJS.Timeout | null = null;

    return function (this: any, ...args: Parameters<T>) {
        if (timeout) {
            clearTimeout(timeout);
        }

        timeout = setTimeout(() => {
            timeout = null;
            func.apply(this, args);
        }, waitMs);
    };
}

/**
 * Chunk large arrays for processing
 */
export function* chunkArray<T>(array: T[], chunkSize: number): Generator<T[]> {
    for (let i = 0; i < array.length; i += chunkSize) {
        yield array.slice(i, i + chunkSize);
    }
}

/**
 * Memory-efficient map operation using generators
 */
export function* mapGenerator<T, U>(
    iterable: Iterable<T>,
    mapper: (item: T) => U
): Generator<U> {
    for (const item of iterable) {
        yield mapper(item);
    }
}

/**
 * Memory-efficient filter operation using generators
 */
export function* filterGenerator<T>(
    iterable: Iterable<T>,
    predicate: (item: T) => boolean
): Generator<T> {
    for (const item of iterable) {
        if (predicate(item)) {
            yield item;
        }
    }
}
