import React from 'react';
import { Box, Play, Square, Activity } from 'lucide-react';

type Container = {
    Id: string;
    Names: string[];
    Image: string;
    State: string;
    Status: string;
};

const ContainerList: React.FC = () => {
    const [containers, setContainers] = React.useState<Container[]>([]);
    const [loading, setLoading] = React.useState(true);
    const [error, setError] = React.useState<string | null>(null);

    React.useEffect(() => {
        fetch('/api/containers')
            .then((res) => {
                if (!res.ok) throw new Error('Network response was not ok');
                return res.json();
            })
            .then((data) => {
                setContainers(data);
                setLoading(false);
            })
            .catch((err) => {
                console.error('Error fetching containers:', err);
                setError('Failed to load container data');
                setLoading(false);
            });
    }, []);

    const stats = [
        { label: 'Total Instances', value: containers.length, icon: Box, color: 'text-indigo-400', bg: 'bg-indigo-500/10 border-indigo-500/20' },
        { label: 'Running Now', value: containers.filter(c => c.State === 'running').length, icon: Play, color: 'text-green-400', bg: 'bg-green-500/10 border-green-500/20' },
        { label: 'Stopped Tasks', value: containers.filter(c => c.State !== 'running').length, icon: Square, color: 'text-slate-400', bg: 'bg-slate-500/10 border-slate-500/20' },
        { label: 'Docker Health', value: '100%', icon: Activity, color: 'text-blue-400', bg: 'bg-blue-500/10 border-blue-500/20' },
    ];

    if (loading) return (
        <div className="flex animate-pulse space-x-4">
            <div className="flex-1 space-y-6 py-1">
                <div className="h-4 bg-slate-700 rounded-lg w-3/4"></div>
                <div className="space-y-3">
                    <div className="h-4 bg-slate-700 rounded-lg"></div>
                    <div className="h-4 bg-slate-700 rounded-lg w-5/6"></div>
                </div>
            </div>
        </div>
    );

    if (error) return (
        <div className="p-6 bg-red-500/10 border border-red-500/20 rounded-2xl text-red-500 flex items-center gap-3">
            <Activity className="w-5 h-5" />
            <span className="font-medium">Docker Daemon Sync Error: {error}</span>
        </div>
    );

    return (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
            {/* Stats Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                {stats.map((stat, i) => (
                    <div key={i} className={`p-6 rounded-2xl border ${stat.bg} backdrop-blur-sm`}>
                        <div className="flex items-center justify-between mb-4">
                            <span className="text-slate-400 text-xs font-bold uppercase tracking-wider">{stat.label}</span>
                            <stat.icon className={`w-5 h-5 ${stat.color}`} />
                        </div>
                        <div className="text-3xl font-bold text-white tracking-tight">{stat.value}</div>
                    </div>
                ))}
            </div>

            {/* Container Table */}
            <div className="bg-[#1e293b] rounded-2xl border border-slate-700/50 overflow-hidden shadow-2xl">
                <div className="p-6 border-b border-slate-700/50 flex items-center justify-between bg-slate-800/20">
                    <h3 className="text-lg font-bold text-white">Docker Honeypot Instances</h3>
                    <div className="flex gap-2">
                        <button className="px-3 py-1 bg-indigo-500 hover:bg-indigo-600 text-white rounded-lg text-xs font-bold transition-all shadow-lg shadow-indigo-500/20">Restart All</button>
                    </div>
                </div>
                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-slate-700/50">
                        <thead className="bg-[#1e293b]">
                            <tr>
                                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">Instance Name</th>
                                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">Base Image</th>
                                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">State</th>
                                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">Status / Runtime</th>
                                <th className="px-8 py-4 text-right text-[10px] font-bold text-slate-500 uppercase tracking-widest">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-700/50 bg-[#1e293b]">
                            {containers.map((container) => (
                                <tr key={container.Id} className="hover:bg-slate-800/30 transition-colors group">
                                    <td className="px-8 py-5 whitespace-nowrap">
                                        <span className="text-sm font-bold text-slate-200">{container.Names[0].replace(/^\//, '')}</span>
                                    </td>
                                    <td className="px-8 py-5 whitespace-nowrap text-sm text-slate-400 font-mono tracking-tighter truncate max-w-[200px]">
                                        {container.Image}
                                    </td>
                                    <td className="px-8 py-5 whitespace-nowrap">
                                        <span className={`px-2 py-1 text-[10px] font-black uppercase tracking-widest rounded-md ${container.State === 'running' ? 'bg-green-500/10 text-green-500' : 'bg-slate-500/20 text-slate-400'
                                            }`}>
                                            {container.State}
                                        </span>
                                    </td>
                                    <td className="px-8 py-5 whitespace-nowrap text-xs text-slate-500 font-medium italic">{container.Status}</td>
                                    <td className="px-8 py-5 whitespace-nowrap text-right">
                                        <div className="flex items-center justify-end gap-2 opacity-0 group-hover:opacity-100 transition-all">
                                            <button className="p-1.5 hover:bg-slate-700 rounded-lg text-slate-400 hover:text-white transition-all"><Play className="w-4 h-4" /></button>
                                            <button className="p-1.5 hover:bg-slate-700 rounded-lg text-slate-400 hover:text-white transition-all"><Square className="w-4 h-4" /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                            {containers.length === 0 && (
                                <tr>
                                    <td colSpan={5} className="px-8 py-10 text-center text-slate-500 italic text-sm">No containers detected. Make sure Docker is running.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

export default ContainerList;
