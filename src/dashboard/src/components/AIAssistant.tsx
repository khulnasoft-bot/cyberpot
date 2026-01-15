import React, { useState, useEffect } from 'react';
import { Brain, Sparkles, ShieldCheck, Zap } from 'lucide-react';

type AnalysisResult = {
    analysis: string;
};

const AIAssistant: React.FC<{ latestLog: string }> = ({ latestLog }) => {
    const [analysis, setAnalysis] = useState<string>('');
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (!latestLog) return;

        setLoading(true);
        fetch('/api/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ log: latestLog }),
        })
            .then(res => res.json())
            .then((data: AnalysisResult) => {
                setAnalysis(data.analysis);
                setLoading(false);
            })
            .catch(err => {
                console.error("AI Analysis failed", err);
                setLoading(false);
            });
    }, [latestLog]);

    return (
        <div className="bg-indigo-600/10 rounded-2xl border border-indigo-500/30 overflow-hidden">
            <div className="p-4 bg-indigo-500/10 flex items-center justify-between border-b border-indigo-500/20">
                <div className="flex items-center gap-2">
                    <Brain className="w-4 h-4 text-indigo-400" />
                    <span className="text-xs font-bold text-white uppercase tracking-widest">AI Threat Intelligence</span>
                </div>
                <Sparkles className="w-3 h-3 text-indigo-400 animate-pulse" />
            </div>

            <div className="p-5 space-y-4">
                <div className="flex items-start gap-4">
                    <div className="w-8 h-8 rounded-full bg-indigo-500/20 flex items-center justify-center shrink-0 border border-indigo-500/40">
                        <Zap className="w-4 h-4 text-indigo-400" />
                    </div>
                    <div className="space-y-1">
                        <div className="text-[10px] font-bold text-slate-500 uppercase">Contextual Insight</div>
                        <div className="text-sm font-medium text-slate-300 leading-relaxed italic">
                            "{latestLog}"
                        </div>
                    </div>
                </div>

                <div className="p-4 bg-slate-900/50 rounded-xl border border-indigo-500/10">
                    {loading ? (
                        <div className="flex items-center gap-2 text-indigo-400 text-xs font-bold animate-pulse">
                            <div className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce"></div>
                            NEURAL CORE PROCESSING...
                        </div>
                    ) : (
                        <p className="text-xs text-slate-400 leading-relaxed font-medium">
                            {analysis}
                        </p>
                    )}
                </div>

                <div className="flex items-center justify-between pt-2">
                    <div className="flex items-center gap-1.5 px-2 py-0.5 bg-green-500/10 rounded-full border border-green-500/20">
                        <ShieldCheck className="w-3 h-3 text-green-500" />
                        <span className="text-[8px] font-bold text-green-500 uppercase">Auto-Mitigation Active</span>
                    </div>
                    <button className="text-[9px] font-bold text-indigo-400 uppercase tracking-widest hover:text-indigo-300 transition-colors">
                        Full Report →
                    </button>
                </div>
            </div>
        </div>
    );
};

export default AIAssistant;
