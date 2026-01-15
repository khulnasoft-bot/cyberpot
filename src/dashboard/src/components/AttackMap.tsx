import React, { useEffect, useState, useMemo, useCallback, useRef } from 'react';
import { ComposableMap, Geographies, Geography, Marker } from 'react-simple-maps';
import { ShieldAlert, Globe } from 'lucide-react';
import { useResourceMode, useFeatureFlags } from '../hooks/useResourceMode';

const geoUrl = "https://cdn.jsdelivr.net/npm/world-atlas@2/countries-110m.json";

type AttackPoint = {
    id: number;
    lat: number;
    lng: number;
    city: string;
    country: string;
    type: string;
    color: string;
};

const AttackMap: React.FC = () => {
    const [attacks, setAttacks] = useState<AttackPoint[]>([]);
    const [loading, setLoading] = useState(true);
    const { resourceMode } = useResourceMode();
    const { enableAnimations, maxVisibleItems, updateInterval } = useFeatureFlags();
    const previousAttacksRef = useRef<AttackPoint[]>([]);

    // Fetch geodata with adaptive polling
    useEffect(() => {
        let mounted = true;
        let timeoutId: NodeJS.Timeout;

        const fetchData = async (incremental = false) => {
            try {
                const url = incremental && previousAttacksRef.current.length > 0
                    ? 'http://localhost:3000/api/geodata?incremental=true'
                    : 'http://localhost:3000/api/geodata';

                const res = await fetch(url);
                const data = await res.json();

                if (!mounted) return;

                if (data.incremental && data.diff) {
                    // Apply incremental update
                    setAttacks(prev => {
                        let updated = [...prev];

                        // Remove deleted items
                        if (data.diff.removed?.length > 0) {
                            const removedIds = new Set(data.diff.removed.map((a: AttackPoint) => a.id));
                            updated = updated.filter(a => !removedIds.has(a.id));
                        }

                        // Add new items
                        if (data.diff.added?.length > 0) {
                            updated = [...updated, ...data.diff.added];
                        }

                        // Update existing items
                        if (data.diff.updated?.length > 0) {
                            const updatedMap = new Map(data.diff.updated.map((a: AttackPoint) => [a.id, a]));
                            updated = updated.map(a => updatedMap.get(a.id) || a);
                        }

                        previousAttacksRef.current = updated;
                        return updated;
                    });
                } else {
                    // Full update
                    setAttacks(data);
                    previousAttacksRef.current = data;
                }

                setLoading(false);
            } catch (err) {
                console.error('Failed to fetch geodata', err);
                if (!mounted) return;
                setLoading(false);
            }

            // Schedule next update based on resource mode
            if (mounted) {
                timeoutId = setTimeout(() => fetchData(true), updateInterval);
            }
        };

        fetchData(false);

        return () => {
            mounted = false;
            if (timeoutId) clearTimeout(timeoutId);
        };
    }, [updateInterval]);

    if (loading) return (
        <div className="h-[600px] flex items-center justify-center bg-[#1e293b] rounded-2xl border border-slate-700/50">
            <div className="flex flex-col items-center gap-4 text-slate-400">
                <Globe className="w-8 h-8 animate-spin" />
                <span className="font-bold uppercase tracking-widest text-xs">Initializing Global Surveillance...</span>
            </div>
        </div>
    );

    return (
        <div className="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-700">
            <div className="grid grid-cols-1 lg:grid-cols-4 gap-6">
                <div className="lg:col-span-3 bg-[#1e293b] rounded-2xl border border-slate-700/50 overflow-hidden shadow-2xl relative">
                    <div className="absolute top-6 left-6 z-10 space-y-2">
                        <h3 className="text-lg font-bold text-white flex items-center gap-2">
                            <span className="w-2 h-2 bg-red-500 rounded-full animate-ping"></span>
                            Tactical Threat Map
                        </h3>
                        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest">Active Intercept Projection</p>
                    </div>

                    <div className="p-4 bg-slate-900/50 flex items-center justify-center">
                        <ComposableMap projection="geoEqualEarth" width={800} height={450}>
                            <Geographies geography={geoUrl}>
                                {({ geographies }: { geographies: any[] }) =>
                                    geographies.map((geo: any) => (
                                        <Geography
                                            key={geo.rsmKey}
                                            geography={geo}
                                            fill="#0f172a"
                                            stroke="#334155"
                                            strokeWidth={0.5}
                                            style={{
                                                default: { outline: "none" },
                                                hover: { fill: "#1e293b", outline: "none" },
                                                pressed: { outline: "none" },
                                            }}
                                        />
                                    ))
                                }
                            </Geographies>
                            {attacks.slice(0, maxVisibleItems).map((point) => (
                                <Marker key={point.id} coordinates={[point.lng, point.lat]}>
                                    <circle r={4} fill={point.color} className={enableAnimations ? "animate-pulse" : ""} />
                                    {enableAnimations && (
                                        <circle r={10} fill={point.color} fillOpacity={0.2} stroke={point.color} strokeWidth={1} className="animate-ping" />
                                    )}
                                    <text
                                        textAnchor="middle"
                                        y={-15}
                                        style={{ fontFamily: "monospace", fill: "#94a3b8", fontSize: "8px", fontWeight: "bold" }}
                                    >
                                        {point.city}
                                    </text>
                                </Marker>
                            ))}
                        </ComposableMap>
                    </div>

                    <div className="absolute bottom-6 right-6 flex items-center gap-4 bg-slate-900/80 backdrop-blur px-4 py-2 rounded-lg border border-slate-700">
                        <div className="flex items-center gap-2">
                            <span className="w-2 h-2 bg-[#f87171] rounded-full"></span>
                            <span className="text-[8px] font-bold text-slate-400 uppercase tracking-tighter">High Threat</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <span className="w-2 h-2 bg-[#6366f1] rounded-full"></span>
                            <span className="text-[8px] font-bold text-slate-400 uppercase tracking-tighter">Medium Threat</span>
                        </div>
                    </div>
                </div>

                <div className="space-y-6">
                    <div className="bg-[#1e293b] p-6 rounded-2xl border border-slate-700/50">
                        <h4 className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-4">Node Analytics</h4>
                        <div className="space-y-4">
                            {attacks.slice(0, Math.min(4, maxVisibleItems)).map((attack, i) => (
                                <div key={attack.id} className="p-3 bg-slate-800/50 rounded-xl border border-slate-700/30 flex items-center justify-between">
                                    <div>
                                        <div className="text-[10px] font-bold text-slate-500 uppercase">{attack.country}</div>
                                        <div className="text-sm font-bold text-white">{attack.city}</div>
                                    </div>
                                    <div className="text-right">
                                        <div className="text-[10px] font-bold text-red-400 uppercase">{attack.type}</div>
                                        <div className="text-[8px] text-slate-500 italic">Target: Hive-01</div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    <div className="bg-indigo-500/10 p-6 rounded-2xl border border-indigo-500/20">
                        <ShieldAlert className="w-6 h-6 text-indigo-400 mb-2" />
                        <h4 className="text-sm font-bold text-white mb-2">Automated Countermeasures</h4>
                        <p className="text-[10px] text-slate-400 leading-relaxed uppercase font-medium">BGP Blackhole enabled for detected adversarial infrastructure in RU/CN sectors.</p>
                        <div className="mt-3 pt-3 border-t border-indigo-500/20">
                            <div className="text-[8px] text-slate-500 uppercase font-bold">Resource Mode: {resourceMode.mode}</div>
                            <div className="text-[8px] text-slate-500">Update Interval: {updateInterval}ms</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AttackMap;
