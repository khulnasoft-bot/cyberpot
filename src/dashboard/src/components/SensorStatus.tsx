import React, { useState, useEffect } from 'react';
import { Radio, Activity, Globe, ShieldAlert } from 'lucide-react';
import AIAssistant from './AIAssistant';

type Sensor = {
  id: string;
  name: string;
  status: 'online' | 'offline' | 'compromised';
  ip: string;
  lastSeen: string;
};

const SensorStatus: React.FC = () => {
  const [sensors, setSensors] = useState<Sensor[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [feed, setFeed] = useState([
    { time: '16:14:02', sensor: 'Pi-Sensor-01', source: '45.155.205.233', country: 'RU', type: 'SSH Brute Force' },
    { time: '16:13:58', sensor: 'Cloud-Sensor-01', source: '210.12.33.15', country: 'CN', type: 'Log4j Attempt' },
    { time: '16:13:45', sensor: 'Pi-Sensor-01', source: '185.122.3.91', country: 'UA', type: 'Telnet Access' },
    { time: '16:13:30', sensor: 'Edge-Pi-01', source: '103.45.12.8', country: 'JP', type: 'SQL Injection' },
  ]);

  useEffect(() => {
    fetch('/api/sensors')
      .then((res) => {
        if (!res.ok) throw new Error('Network response was not ok');
        return res.json();
      })
      .then((data) => {
        setSensors(data);
        setLoading(false);
      })
      .catch((err) => {
        console.error('Error fetching data:', err);
        setError('Failed to load sensor data');
        setLoading(false);
      });

    // Simulate new attacks every 5s
    const interval = setInterval(() => {
      const types = ['SSH Brute Force', 'Log4j Attempt', 'Telnet Access', 'Scanner', 'DDoS Stream'];
      const countries = ['RU', 'CN', 'US', 'GB', 'DE', 'NL'];
      const newAttack = {
        time: new Date().toLocaleTimeString(),
        sensor: 'Edge-Node-' + Math.floor(Math.random() * 5),
        source: `${Math.floor(Math.random() * 255)}.${Math.floor(Math.random() * 255)}.12.5`,
        country: countries[Math.floor(Math.random() * countries.length)],
        type: types[Math.floor(Math.random() * types.length)]
      };
      setFeed(prev => [newAttack, ...prev].slice(0, 10));
    }, 8000);

    return () => clearInterval(interval);
  }, []);

  const stats = [
    { label: 'Total Sensors', value: sensors.length, icon: Radio, color: 'text-indigo-400', bg: 'bg-indigo-500/10 border-indigo-500/20' },
    { label: 'Active Alerts', value: '12', icon: ShieldAlert, color: 'text-red-400', bg: 'bg-red-500/10 border-red-500/20' },
    { label: 'Network Load', value: '4.2k ops/s', icon: Activity, color: 'text-green-400', bg: 'bg-green-500/10 border-green-500/20' },
    { label: 'Global Reach', value: '18 Nodes', icon: Globe, color: 'text-blue-400', bg: 'bg-blue-500/10 border-blue-500/20' },
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
      <ShieldAlert className="w-5 h-5" />
      <span className="font-medium">Command Center Sync Error: {error}</span>
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

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Live Attack Feed Simulation */}
        <div className="lg:col-span-2 bg-[#1e293b] rounded-2xl border border-slate-700/50 overflow-hidden shadow-2xl flex flex-col h-[400px]">
          <div className="p-6 border-b border-slate-700/50 flex items-center justify-between bg-red-500/5">
            <h3 className="text-lg font-bold text-white flex items-center gap-3">
              <span className="relative flex h-3 w-3">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-red-500"></span>
              </span>
              Live Attack Intercepts
            </h3>
            <span className="text-[10px] font-bold text-red-400 uppercase tracking-widest px-2 py-1 bg-red-500/10 rounded-md shadow-sm border border-red-500/20">Real-time Stream</span>
          </div>
          <div className="flex-1 overflow-y-auto p-2 space-y-1 bg-slate-900/40 custom-scrollbar">
            {feed.map((attack, i) => (
              <div key={i} className={`flex items-center gap-4 p-4 rounded-xl transition-all border border-transparent group ${i === 0 ? 'bg-indigo-500/5 border-indigo-500/20' : 'hover:bg-slate-800/50 hover:border-slate-700/50'}`}>
                <span className="text-xs font-mono text-slate-500">{attack.time}</span>
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider px-2 py-0.5 bg-slate-800 rounded">{attack.sensor}</span>
                <span className={`text-sm font-mono font-medium ${i === 0 ? 'text-indigo-400' : 'text-slate-400'}`}>{attack.source}</span>
                <span className={`text-xs ml-auto transition-colors font-bold uppercase tracking-widest ${i === 0 ? 'text-red-400' : 'text-slate-500 group-hover:text-red-400'}`}>{attack.type}</span>
              </div>
            ))}
          </div>
          <div className="p-4 text-center border-t border-slate-700/30">
            <button className="text-[10px] font-bold text-slate-500 hover:text-white transition-all uppercase tracking-widest">Connect to ELK for Full Logs</button>
          </div>
        </div>

        {/* AI Analysis Panel */}
        <div className="lg:col-span-1">
          <AIAssistant latestLog={feed[0]?.type || ''} />
        </div>
      </div>

      {/* Sensor Table */}
      <div className="bg-[#1e293b] rounded-2xl border border-slate-700/50 overflow-hidden shadow-2xl">
        <div className="p-6 border-b border-slate-700/50 flex items-center justify-between bg-slate-800/20">
          <h3 className="text-lg font-bold text-white">Active Distributed Sensors</h3>
          <button className="text-xs font-bold text-indigo-400 hover:text-indigo-300 uppercase tracking-widest">Refresh Feed</button>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-700/50">
            <thead className="bg-[#1e293b]">
              <tr>
                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">Name</th>
                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">Status</th>
                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">IP Address</th>
                <th className="px-8 py-4 text-left text-[10px] font-bold text-slate-500 uppercase tracking-widest">Discovery</th>
                <th className="px-8 py-4 ml-auto text-right text-[10px] font-bold text-slate-500 uppercase tracking-widest">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50 bg-[#1e293b]">
              {sensors.map((sensor) => (
                <tr key={sensor.id} className="hover:bg-slate-800/30 transition-colors group">
                  <td className="px-8 py-5 whitespace-nowrap">
                    <div className="flex items-center gap-3">
                      <div className={`w-2 h-2 rounded-full ${sensor.status === 'online' ? 'bg-green-500' : sensor.status === 'offline' ? 'bg-slate-500' : 'bg-red-500'}`}></div>
                      <span className="text-sm font-semibold text-slate-200">{sensor.name}</span>
                    </div>
                  </td>
                  <td className="px-8 py-5 whitespace-nowrap">
                    <span className={`px-2 py-1 text-[10px] font-black uppercase tracking-widest rounded-md ${sensor.status === 'online' ? 'bg-green-500/10 text-green-500' :
                      sensor.status === 'offline' ? 'bg-slate-500/20 text-slate-400' :
                        'bg-red-500/10 text-red-500'
                      }`}>
                      {sensor.status}
                    </span>
                  </td>
                  <td className="px-8 py-5 whitespace-nowrap text-sm text-slate-400 font-mono tracking-tighter">{sensor.ip}</td>
                  <td className="px-8 py-5 whitespace-nowrap text-xs text-slate-500 font-medium italic">{sensor.lastSeen}</td>
                  <td className="px-8 py-5 whitespace-nowrap text-right">
                    <button className="text-slate-400 hover:text-white text-xs font-bold uppercase tracking-widest opacity-0 group-hover:opacity-100 transition-all">
                      Details
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

export default SensorStatus;
