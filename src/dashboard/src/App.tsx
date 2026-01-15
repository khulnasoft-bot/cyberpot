import React, { useState } from 'react';
import { Radio, Shield, Settings, Menu, X, Bell, Globe } from 'lucide-react';
import SensorStatus from './components/SensorStatus';
import ContainerList from './components/ContainerList';
import AttackMap from './components/AttackMap';

const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'sensors' | 'containers' | 'global'>('sensors');
  const [isSidebarOpen, setSidebarOpen] = useState(true);

  const menuItems = [
    { id: 'sensors', label: 'Sensors', icon: Radio },
    { id: 'global', label: 'Global View', icon: Globe },
    { id: 'containers', label: 'Containers', icon: Shield },
  ];

  return (
    <div className="min-h-screen bg-[#0f172a] text-slate-200 flex overflow-hidden font-sans">
      {/* Sidebar */}
      <aside className={`${isSidebarOpen ? 'w-64' : 'w-20'} bg-[#1e293b] border-r border-slate-700/50 transition-all duration-300 flex flex-col z-20`}>
        <div className="p-6 flex items-center gap-3">
          <div className="w-8 h-8 bg-indigo-500 rounded-lg flex items-center justify-center">
            <Shield className="text-white w-5 h-5" />
          </div>
          {isSidebarOpen && <span className="font-bold text-xl tracking-tight text-white uppercase italic">CyberPot</span>}
        </div>

        <nav className="flex-1 px-4 py-4 space-y-1">
          {menuItems.map((item) => (
            <button
              key={item.id}
              onClick={() => setActiveTab(item.id as any)}
              className={`w-full flex items-center gap-3 px-3 py-3 rounded-xl transition-all ${activeTab === item.id
                ? 'bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 shadow-[0_0_15px_rgba(99,102,241,0.1)]'
                : 'text-slate-400 hover:bg-slate-800/50 hover:text-slate-200'
                }`}
            >
              <item.icon className={`w-5 h-5 ${activeTab === item.id ? 'text-indigo-400' : ''}`} />
              {isSidebarOpen && <span className="font-medium text-sm">{item.label}</span>}
            </button>
          ))}
        </nav>

        <div className="p-4 border-t border-slate-700/50">
          <button className="w-full flex items-center gap-3 px-3 py-3 text-slate-400 hover:bg-slate-800/50 rounded-xl transition-all">
            <Settings className="w-5 h-5" />
            {isSidebarOpen && <span className="font-medium text-sm">Settings</span>}
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col h-screen overflow-hidden">
        {/* Top Header */}
        <header className="h-16 bg-[#0f172a]/80 backdrop-blur-md border-b border-slate-700/50 flex items-center justify-between px-8 shrink-0">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setSidebarOpen(!isSidebarOpen)}
              className="p-2 hover:bg-slate-800 rounded-lg text-slate-400"
            >
              {isSidebarOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
            <h2 className="text-lg font-semibold text-white capitalize">{activeTab} Dashboard</h2>
          </div>

          <div className="flex items-center gap-4">
            <div className="flex items-center px-3 py-1 bg-green-500/10 border border-green-500/20 rounded-full">
              <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse mr-2"></span>
              <span className="text-[10px] font-bold text-green-500 uppercase tracking-widest">System Active</span>
            </div>
            <button className="relative p-2 text-slate-400 hover:text-white transition-colors">
              <Bell className="w-5 h-5" />
              <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 border-2 border-[#0f172a] rounded-full"></span>
            </button>
            <div className="flex items-center gap-3 pl-4 border-l border-slate-700/50">
              <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-500 flex items-center justify-center text-white text-xs font-bold">
                AD
              </div>
            </div>
          </div>
        </header>

        {/* Scrollable Area */}
        <main className="flex-1 overflow-y-auto p-8 space-y-8 custom-scrollbar">
          {activeTab === 'sensors' && <SensorStatus />}
          {activeTab === 'global' && <AttackMap />}
          {activeTab === 'containers' && <ContainerList />}
        </main>
      </div>

      <style>{`
        .custom-scrollbar::-webkit-scrollbar {
          width: 6px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
          background: #0f172a;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
          background: #334155;
          border-radius: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
          background: #475569;
        }
      `}</style>
    </div>
  );
};

export default App;
