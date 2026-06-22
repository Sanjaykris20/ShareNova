import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Send, Download, Search, FileText, Image as ImageIcon, Video, 
  MoreVertical, Wifi, Camera, Clock, User, Crown, 
  CheckCircle2, X, Grid, Zap, ShieldCheck, Share2,
  FolderOpen, Lock, QrCode, Monitor, Trash2, CheckSquare, 
  ArrowRight, ArrowLeft, BarChart3, Users, RefreshCcw, 
  Timer, XOctagon, Key, Activity, ServerOff, Fingerprint as FingerprintIcon, 
  EyeOff, AlertTriangle, Copy, Link as LinkIcon,
  Smartphone, Laptop, Phone, Compass, HardDrive, 
  SmartphoneCharging, Globe, Gift, PlaySquare, Settings, ChevronRight,
  Info, ShieldAlert, Check, HelpCircle, Play, Pause, MessageSquare, 
  Paperclip, Mic, CheckCheck, FileUp, FileDown, Radio, Menu, Music, ScanLine
} from 'lucide-react';

const RECENT_TRANSFERS = [
  { id: 1, name: "Project_Presentation.pdf", type: "doc", size: "12.4 MB", time: "1 hour ago", status: "completed", encrypted: true },
  { id: 2, name: "Confidential_Specs.docx", type: "doc", size: "2.1 MB", time: "3 hours ago", status: "active", expires: "24h", encrypted: true },
  { id: 3, name: "Vacation_Video.mp4", type: "video", size: "1.2 GB", time: "Yesterday", status: "completed", encrypted: true },
];

const MOCK_APPS = [
  { id: 1, name: "WhatsApp", size: "85 MB", icon: "https://api.dicebear.com/7.x/identicon/svg?seed=wa&backgroundColor=25D366" },
  { id: 2, name: "Instagram", size: "120 MB", icon: "https://api.dicebear.com/7.x/identicon/svg?seed=ig&backgroundColor=E1306C" },
  { id: 3, name: "Signal", size: "45 MB", icon: "https://api.dicebear.com/7.x/identicon/svg?seed=sig&backgroundColor=3b82f6" },
  { id: 4, name: "Spotify", size: "45 MB", icon: "https://api.dicebear.com/7.x/identicon/svg?seed=sp&backgroundColor=1DB954" },
];

const MOCK_CONTACTS = [
  { id: 'c1', name: "Sarah Jenkins", phone: "+1 555-0123", initials: "SJ", color: "bg-purple-100 text-purple-600", status: "Nearby (Wi-Fi Direct)", lastMsg: "Can you send the 4K video?", unread: 2 },
  { id: 'c2', name: "David Chen", phone: "+1 555-0198", initials: "DC", color: "bg-blue-100 text-blue-600", status: "Offline", lastMsg: "Thanks for the files!", unread: 0 },
  { id: 'c3', name: "Mom", phone: "+1 555-0001", initials: "M", color: "bg-pink-100 text-pink-600", status: "Online (Cloud Relay)", lastMsg: "Are we still on for dinner?", unread: 0 },
  { id: 'c4', name: "Project Group", phone: "4 Members", initials: "PG", color: "bg-emerald-100 text-emerald-600", status: "2 Members Nearby", lastMsg: "Alex sent a document.", unread: 5 },
];

const MOCK_CHAT_MESSAGES = [
  { id: 1, sender: 'Sarah Jenkins', text: "Hey! Did you finish editing the vacation video?", time: "10:42 AM", isMine: false, type: 'text' },
  { id: 2, sender: 'Me', text: "Yes! Just exported it in 4K.", time: "10:45 AM", isMine: true, type: 'text' },
  { id: 3, sender: 'Sarah Jenkins', text: "Awesome. Can you beam it over?", time: "10:46 AM", isMine: false, type: 'text' },
  { id: 4, sender: 'Sarah Jenkins', type: 'request', fileName: "Vacation_Edit_Final.mp4", fileType: "video", time: "10:46 AM", isMine: false },
  { id: 5, sender: 'Me', type: 'transfer', fileName: "Vacation_Edit_Final.mp4", size: "1.2 GB", status: "completed", time: "10:48 AM", isMine: true },
  { id: 6, sender: 'Sarah Jenkins', text: "Got it! Speeds were insane. 120MB/s! 🚀", time: "10:49 AM", isMine: false, type: 'text' },
];

const MOCK_DISCOVER_NEWS = [
  { id: 1, title: "10 Tips for Faster Wi-Fi Direct Transfers", source: "TechRadar", time: "2h ago", image: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=200&h=200&fit=crop" },
  { id: 2, title: "The Future of P2P Encrypted Sharing", source: "Security Weekly", time: "5h ago", image: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=200&h=200&fit=crop" },
  { id: 3, title: "Top 5 Productivity Apps of 2026", source: "App Digest", time: "1d ago", image: "https://images.unsplash.com/photo-1611162617474-5b21e879e113?w=200&h=200&fit=crop" },
];

const MOCK_FEATURED_APPS = [
  { id: 5, name: "TikTok", size: "110 MB", category: "Editor's Pick", icon: "https://api.dicebear.com/7.x/identicon/svg?seed=tk&backgroundColor=000000" },
  { id: 6, name: "Netflix", size: "88 MB", category: "Trending", icon: "https://api.dicebear.com/7.x/identicon/svg?seed=nf&backgroundColor=E50914" },
  { id: 7, name: "CapCut", size: "140 MB", category: "New Arrival", icon: "https://api.dicebear.com/7.x/identicon/svg?seed=cc&backgroundColor=111111" },
];

const MOCK_MUSIC = [
  { id: 'm1', title: "Midnight City", artist: "M83", size: "8.2 MB", cover: "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=150&h=150&fit=crop" },
  { id: 'm2', title: "Starboy", artist: "The Weeknd", size: "9.1 MB", cover: "https://images.unsplash.com/photo-1619983081563-430f63602796?w=150&h=150&fit=crop" },
  { id: 'm3', title: "Blinding Lights", artist: "The Weeknd", size: "7.5 MB", cover: "https://images.unsplash.com/photo-1493225457124-a1a2a5f56468?w=150&h=150&fit=crop" },
  { id: 'm4', title: "Levitating", artist: "Dua Lipa", size: "8.8 MB", cover: "https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=150&h=150&fit=crop" },
];

const ScreenTransition = ({ children, className = "" }) => (
  <motion.div
    initial={{ opacity: 0, x: 20 }}
    animate={{ opacity: 1, x: 0 }}
    exit={{ opacity: 0, x: -20 }}
    transition={{ duration: 0.3, ease: "easeOut" }}
    className={`w-full h-full flex flex-col overflow-hidden relative ${className}`}
  >
    {children}
  </motion.div>
);

const ScreenHeader = ({ title, onBack, rightIcon, subtitle }) => (
  <div className="px-6 py-4 flex items-center justify-between border-b border-gray-100 bg-white/80 backdrop-blur-md z-20 sticky top-0">
    <div className="flex items-center space-x-3">
      {onBack && (
        <button onClick={onBack} className="p-2 -ml-2 rounded-full hover:bg-gray-100 transition-colors">
          <ArrowLeft size={24} className="text-gray-900" />
        </button>
      )}
      <div className="flex flex-col">
         <h2 className="text-xl font-extrabold text-gray-900 tracking-tight leading-tight">{title}</h2>
         {subtitle && <span className="text-xs font-bold text-gray-500">{subtitle}</span>}
      </div>
    </div>
    {rightIcon}
  </div>
);

const RadarIcon = ({ size }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M19.07 4.93A10 10 0 0 0 6.99 3.34"/><path d="M4 6h.01"/><path d="M2.29 9.62A10 10 0 1 0 21.31 8.35"/><path d="M16.24 7.76A6 6 0 1 0 8.23 16.67"/><path d="M12 18h.01"/><path d="M17.99 11.66A6 6 0 0 1 15.77 16.67"/><path d="M12 12h.01"/><path d="M16.8 15.8c-1.5 2-4.6 2-6.1 0"/>
  </svg>
);

const StarIcon = ({ size, className }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className} stroke="none">
    <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
  </svg>
);

const SplashScreen = ({ onComplete }) => {
  useEffect(() => {
    const timer = setTimeout(onComplete, 1800);
    return () => clearTimeout(timer);
  }, [onComplete]);

  return (
    <motion.div className="w-full h-full bg-blue-600 flex flex-col items-center justify-center relative overflow-hidden" exit={{ opacity: 0 }}>
      <div className="absolute inset-0 bg-gradient-to-br from-blue-400/20 to-purple-600/20" />
      <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="relative z-10 flex flex-col items-center">
        <div className="w-24 h-24 bg-white rounded-3xl shadow-2xl flex items-center justify-center mb-6">
          <Zap size={48} className="text-blue-600" fill="currentColor" />
        </div>
        <h1 className="text-4xl font-extrabold text-white tracking-tighter mb-2">ShareNova</h1>
        <div className="flex items-center space-x-2 bg-blue-700/50 px-4 py-1.5 rounded-full mt-4 border border-white/10">
           <ShieldCheck size={16} className="text-blue-200" />
           <span className="text-xs font-bold text-blue-100 tracking-wide">P2P Encrypted</span>
        </div>
      </motion.div>
    </motion.div>
  );
};

const HomeScreen = ({ navigate, toggleDrawer }) => (
  <ScreenTransition className="bg-gray-50">
    <div className="px-6 pt-6 pb-4 flex items-center justify-between">
      <div className="flex items-center space-x-3">
         {/* Hamburger Menu for Drawer */}
         <button onClick={toggleDrawer} className="p-2 -ml-2 rounded-full hover:bg-gray-200 transition-colors text-gray-800">
            <Menu size={26} />
         </button>
         <div className="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center p-[2px] shadow-sm relative cursor-pointer hover:scale-105 transition-transform" onClick={() => navigate('profile')}>
           <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" alt="Profile" className="w-full h-full bg-white rounded-full object-cover" />
           <div className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></div>
         </div>
      </div>
      <div className="flex space-x-2">
        <button onClick={() => navigate('history')} className="p-2.5 rounded-full bg-white shadow-sm border border-gray-100 hover:bg-gray-50 text-blue-600 relative">
          <Clock size={20} />
          <span className="absolute top-1 right-1 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white"></span>
        </button>
      </div>
    </div>

    <div className="px-6 flex space-x-4 mb-6 mt-2">
      <motion.button whileTap={{ scale: 0.96 }} onClick={() => navigate('files')} className="flex-1 bg-gradient-to-br from-blue-500 to-blue-700 p-6 rounded-[32px] shadow-[0_15px_30px_rgba(37,99,235,0.3)] flex flex-col items-center justify-center gap-4 relative overflow-hidden group">
        <div className="absolute -top-6 -right-6 w-32 h-32 bg-white/20 rounded-full blur-2xl group-hover:scale-125 transition-transform duration-700"></div>
        <div className="w-14 h-14 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm border border-white/20">
            <Send size={28} className="text-white ml-1" fill="currentColor" />
        </div>
        <span className="text-white font-extrabold text-xl tracking-widest">SEND</span>
      </motion.button>
      
      <motion.button whileTap={{ scale: 0.96 }} onClick={() => navigate('receive')} className="flex-1 bg-gradient-to-br from-emerald-400 to-emerald-600 p-6 rounded-[32px] shadow-[0_15px_30px_rgba(16,185,129,0.3)] flex flex-col items-center justify-center gap-4 relative overflow-hidden group">
        <div className="absolute -bottom-6 -left-6 w-32 h-32 bg-white/20 rounded-full blur-2xl group-hover:scale-125 transition-transform duration-700"></div>
        <div className="w-14 h-14 bg-white/20 rounded-full flex items-center justify-center backdrop-blur-sm border border-white/20">
            <Download size={28} className="text-white" fill="currentColor" />
        </div>
        <span className="text-white font-extrabold text-xl tracking-widest">RECEIVE</span>
      </motion.button>
    </div>

    {/* Auto-Sync and Quick Tools */}
    <div className="px-6 mb-8">
       <div className="bg-white rounded-[28px] p-5 shadow-[0_8px_30px_rgba(0,0,0,0.04)] border border-gray-100 flex justify-between items-center relative overflow-hidden">
          {[
            { icon: RefreshCcw, label: "Auto-Sync", color: "text-blue-500", bg: "bg-blue-50", route: 'autosync' },
            { icon: Users, label: "Rooms", color: "text-purple-500", bg: "bg-purple-50", route: 'workspace' },
            { icon: Monitor, label: "PC Share", color: "text-orange-500", bg: "bg-orange-50", route: 'webshare' },
            { icon: Trash2, label: "Clean", color: "text-gray-500", bg: "bg-gray-100", route: 'clean' },
          ].map((tool, i) => (
            <div key={i} onClick={() => navigate(tool.route)} className="flex flex-col items-center gap-2 cursor-pointer group">
               <div className={`w-12 h-12 rounded-2xl flex items-center justify-center transition-all duration-300 group-hover:scale-110 ${tool.bg}`}>
                 <tool.icon size={22} className={tool.color} />
               </div>
               <span className="text-[11px] font-extrabold text-gray-600">{tool.label}</span>
            </div>
          ))}
       </div>
    </div>

    <div className="flex-1 bg-white rounded-t-[36px] px-6 pt-7 shadow-[0_-10px_40px_rgba(0,0,0,0.03)] overflow-y-auto pb-24 border-t border-gray-100">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-xl font-extrabold text-gray-900 tracking-tight">Recent Activity</h3>
      </div>
      <div className="space-y-4">
        {RECENT_TRANSFERS.map((file) => (
          <div key={file.id} className="flex flex-col p-3 rounded-2xl border border-gray-100 hover:shadow-md transition-shadow bg-gray-50/50 cursor-pointer">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <div className="w-12 h-12 rounded-[16px] bg-white flex items-center justify-center shadow-sm border border-gray-100">
                  {file.type === 'video' ? <Video size={20} className="text-purple-500" /> : <FileText size={20} className="text-blue-500" />}
                </div>
                <div>
                  <p className="font-extrabold text-gray-900 text-sm max-w-[150px] truncate">{file.name}</p>
                  <div className="flex items-center text-[11px] text-gray-500 mt-1 font-bold space-x-2">
                    <span>{file.size}</span><span>•</span><span>{file.time}</span>
                  </div>
                </div>
              </div>
            </div>
            {/* Status Tags */}
            <div className="mt-3 flex items-center space-x-2 pl-16">
               <span className="inline-flex items-center space-x-1 text-[10px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-sm">
                  <Lock size={10} /> <span>E2E Encrypted</span>
               </span>
               {file.status === 'active' && (
                  <span className="inline-flex items-center space-x-1 text-[10px] font-bold text-orange-600 bg-orange-50 px-2 py-0.5 rounded-sm">
                     <Timer size={10} /> <span>Active</span>
                  </span>
               )}
            </div>
          </div>
        ))}
      </div>
    </div>
  </ScreenTransition>
);

const FileManagerScreen = ({ navigate }) => {
  const [selected, setSelected] = useState([]);
  const [showSecurityOptions, setShowSecurityOptions] = useState(false);
  const [expiry, setExpiry] = useState("Never");
  const [activeTab, setActiveTab] = useState('Apps');
  const [requirePassword, setRequirePassword] = useState(false);
  const [transferPassword, setTransferPassword] = useState("");

  const toggleSelect = (id) => setSelected(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);

  return (
    <ScreenTransition className="bg-white">
      <ScreenHeader title="Select Content" onBack={() => navigate('home')} rightIcon={<Search size={22} className="text-gray-600" />} />
      
      <div className="flex px-2 border-b border-gray-100 overflow-x-auto scrollbar-hide shadow-sm">
         {/* Added Music Tab here */}
         {['Apps', 'Contacts', 'Photos', 'Files', 'Videos', 'Music'].map((tab) => (
            <div key={tab} onClick={() => setActiveTab(tab)} className={`px-5 py-4 text-[14px] font-extrabold whitespace-nowrap border-b-[3px] cursor-pointer ${activeTab === tab ? 'border-blue-600 text-blue-600' : 'border-transparent text-gray-400'}`}>
               {tab}
            </div>
         ))}
      </div>

      <div className="flex-1 overflow-y-auto px-6 py-6 pb-32">
         {activeTab === 'Apps' && (
           <div className="grid grid-cols-4 gap-x-4 gap-y-8">
              {MOCK_APPS.map((app) => (
                 <div key={app.id} onClick={() => toggleSelect(app.id)} className="flex flex-col items-center cursor-pointer relative group">
                    <div className="w-[72px] h-[72px] rounded-[20px] mb-2 overflow-hidden shadow-sm relative border border-gray-100">
                       <img src={app.icon} alt={app.name} className={`w-full h-full object-cover transition-transform ${selected.includes(app.id) ? 'scale-110' : ''}`} />
                       <div className={`absolute inset-0 transition-colors ${selected.includes(app.id) ? 'bg-black/20' : ''}`}></div>
                       <div className={`absolute bottom-1.5 right-1.5 w-5 h-5 rounded-full border-2 border-white flex items-center justify-center ${selected.includes(app.id) ? 'bg-blue-600' : 'bg-black/30'}`}>
                          {selected.includes(app.id) && <CheckSquare size={12} className="text-white" fill="currentColor" />}
                       </div>
                    </div>
                    <span className="text-xs font-bold text-gray-800 text-center leading-tight line-clamp-1 w-full">{app.name}</span>
                 </div>
              ))}
           </div>
         )}

         {activeTab === 'Contacts' && (
           <div className="flex flex-col space-y-3">
              <p className="text-xs font-bold text-gray-500 uppercase tracking-wider mb-2">Share vCard Data</p>
              {MOCK_CONTACTS.map((contact) => (
                 <div key={contact.id} onClick={() => toggleSelect(contact.id)} className={`flex items-center justify-between p-3 rounded-2xl border transition-colors cursor-pointer ${selected.includes(contact.id) ? 'bg-blue-50 border-blue-200' : 'bg-white border-gray-100 hover:bg-gray-50'}`}>
                    <div className="flex items-center gap-4">
                       <div className={`w-12 h-12 rounded-full flex items-center justify-center font-black text-lg shadow-sm ${contact.color}`}>
                          {contact.initials}
                       </div>
                       <div>
                          <p className="text-sm font-extrabold text-gray-900">{contact.name}</p>
                          <p className="text-[11px] font-bold text-gray-500 flex items-center gap-1 mt-0.5"><Phone size={10}/> {contact.phone}</p>
                       </div>
                    </div>
                    <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors ${selected.includes(contact.id) ? 'bg-blue-600 border-blue-600' : 'border-gray-300 bg-white'}`}>
                       {selected.includes(contact.id) && <CheckSquare size={14} className="text-white" fill="currentColor" />}
                    </div>
                 </div>
              ))}
           </div>
         )}

         {activeTab === 'Photos' && (
           <div className="grid grid-cols-3 gap-3">
              {[1, 2, 3, 4, 5, 6].map((i) => (
                 <div key={i} onClick={() => toggleSelect(`p${i}`)} className="aspect-square relative rounded-2xl overflow-hidden cursor-pointer shadow-sm">
                    <img src={`https://images.unsplash.com/photo-${1500000000000 + i * 100000}?w=150&h=150&fit=crop`} className="w-full h-full object-cover" alt="Media" />
                    <div className={`absolute inset-0 transition-colors ${selected.includes(`p${i}`) ? 'bg-black/20' : ''}`} />
                    <div className={`absolute top-2 right-2 w-5 h-5 rounded-full border-2 border-white flex items-center justify-center ${selected.includes(`p${i}`) ? 'bg-blue-600' : 'bg-black/30'}`}>
                       {selected.includes(`p${i}`) && <CheckSquare size={12} className="text-white" fill="currentColor" />}
                    </div>
                 </div>
              ))}
           </div>
         )}

         {activeTab === 'Files' && (
           <div className="space-y-3">
              {RECENT_TRANSFERS.map((item) => (
                 <div key={item.id} onClick={() => toggleSelect(`f${item.id}`)} className={`flex items-center justify-between p-4 rounded-2xl border cursor-pointer ${selected.includes(`f${item.id}`) ? 'bg-blue-50 border-blue-200' : 'bg-white border-gray-100'}`}>
                    <div className="flex items-center gap-3">
                       <FileText className="text-blue-500" />
                       <div>
                          <p className="text-sm font-extrabold text-gray-900">{item.name}</p>
                          <p className="text-xs font-bold text-gray-500">{item.size}</p>
                       </div>
                    </div>
                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${selected.includes(`f${item.id}`) ? 'bg-blue-600 border-blue-600' : 'border-gray-300'}`}>
                       {selected.includes(`f${item.id}`) && <CheckSquare size={12} className="text-white" fill="currentColor" />}
                    </div>
                 </div>
              ))}
           </div>
         )}

         {activeTab === 'Videos' && (
           <div className="grid grid-cols-2 gap-3">
              {[1, 2, 3, 4].map((i) => (
                 <div key={i} onClick={() => toggleSelect(`v${i}`)} className="aspect-video relative rounded-2xl overflow-hidden cursor-pointer shadow-sm">
                    <img src={`https://images.unsplash.com/photo-${1511110000000 + i * 12345}?w=250&h=150&fit=crop`} className="w-full h-full object-cover" alt="Media" />
                    <div className="absolute inset-0 bg-black/10 flex items-center justify-center">
                       <Video className="text-white opacity-80" size={24} />
                    </div>
                    <div className={`absolute top-2 right-2 w-5 h-5 rounded-full border-2 border-white flex items-center justify-center ${selected.includes(`v${i}`) ? 'bg-blue-600' : 'bg-black/30'}`}>
                       {selected.includes(`v${i}`) && <CheckSquare size={12} className="text-white" fill="currentColor" />}
                    </div>
                 </div>
              ))}
           </div>
         )}

         {/* New Music Tab Implementation */}
         {activeTab === 'Music' && (
           <div className="space-y-4">
              {MOCK_MUSIC.map((track) => (
                 <div key={track.id} onClick={() => toggleSelect(track.id)} className={`flex items-center justify-between p-3 rounded-2xl border cursor-pointer transition-colors ${selected.includes(track.id) ? 'bg-blue-50 border-blue-200' : 'bg-white border-gray-100 hover:bg-gray-50'}`}>
                    <div className="flex items-center gap-4">
                       <div className="w-12 h-12 rounded-xl overflow-hidden shadow-sm relative">
                          <img src={track.cover} className="w-full h-full object-cover" alt="Album" />
                          <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
                             <Music size={16} className="text-white" />
                          </div>
                       </div>
                       <div>
                          <p className="text-sm font-extrabold text-gray-900">{track.title}</p>
                          <p className="text-[11px] font-bold text-gray-500 mt-0.5">{track.artist} • {track.size}</p>
                       </div>
                    </div>
                     <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors ${selected.includes(track.id) ? 'bg-blue-600 border-blue-600' : 'border-gray-300 bg-white'}`}>
                       {selected.includes(track.id) && <CheckSquare size={14} className="text-white" fill="currentColor" />}
                    </div>
                 </div>
              ))}
           </div>
         )}
      </div>

      {/* Selected Action Footer */}
      <div className="absolute bottom-0 left-0 right-0 p-5 bg-white/95 backdrop-blur-xl border-t border-gray-100 z-40 flex items-center justify-between shadow-[0_-20px_40px_rgba(0,0,0,0.05)]">
         <div className="flex flex-col pl-2">
            <div className="text-[15px] font-extrabold text-gray-900">Selected: <span className="text-blue-600">{selected.length}</span></div>
         </div>
         <button onClick={() => selected.length > 0 ? setShowSecurityOptions(true) : null} className={`px-10 py-4 rounded-[24px] font-extrabold text-white transition-all duration-300 flex items-center space-x-2 ${selected.length > 0 ? 'bg-blue-600 shadow-[0_10px_20px_rgba(37,99,235,0.3)] active:scale-95' : 'bg-gray-200 text-gray-400'}`}>
            <span className="text-[15px]">Next</span> <ArrowRight size={20} />
         </button>
      </div>

      {/* Security Options Drawer */}
      <AnimatePresence>
        {showSecurityOptions && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex flex-col justify-end">
            <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} transition={{ type: "spring", damping: 25, stiffness: 200 }} className="bg-white rounded-t-[40px] p-8 shadow-2xl border-t border-gray-200">
               <div className="flex justify-between items-center mb-6">
                  <div>
                    <h3 className="text-xl font-extrabold text-gray-900 flex items-center gap-2">
                       <ShieldCheck size={24} className="text-emerald-500" />
                       Security & Rules
                    </h3>
                    <p className="text-xs font-bold text-gray-500 mt-1">These rules travel encrypted with the file.</p>
                  </div>
                  <button onClick={() => setShowSecurityOptions(false)} className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center text-gray-600"><X size={18} /></button>
               </div>
               
               <div className="space-y-4 mb-8">
                  {/* Expiry Rule Selection */}
                  <div className="bg-gray-50 p-4 rounded-2xl border border-gray-100">
                     <p className="text-sm font-extrabold text-gray-900 mb-1 flex items-center gap-2"><Timer size={16} className="text-blue-500"/> Auto-Destruct Rule</p>
                     <p className="text-[10px] font-bold text-gray-500 mb-3">Receiver's app will delete the data upon trigger.</p>
                     <div className="flex gap-2">
                        {['Never', '1 View', '24 Hours', '7 Days'].map(opt => (
                           <button key={opt} onClick={() => setExpiry(opt)} className={`flex-1 py-2 rounded-xl text-xs font-extrabold transition-colors ${expiry === opt ? 'bg-blue-600 text-white shadow-md' : 'bg-white text-gray-600 border border-gray-200'}`}>
                              {opt}
                           </button>
                        ))}
                     </div>
                  </div>

                  {/* Password Protection Rule */}
                  <div className="bg-gray-50 p-4 rounded-2xl border border-gray-100">
                     <div className="flex justify-between items-center">
                        <div>
                           <p className="text-sm font-extrabold text-gray-900 flex items-center gap-2"><Key size={16} className="text-purple-500"/> Password Lock</p>
                           <p className="text-[10px] font-bold text-gray-500 mt-0.5">Require a password to receive</p>
                        </div>
                        <button onClick={() => setRequirePassword(!requirePassword)} className={`w-11 h-6 rounded-full p-0.5 transition-colors ${requirePassword ? 'bg-purple-600' : 'bg-gray-300'}`}>
                           <div className={`w-5 h-5 rounded-full bg-white transition-transform ${requirePassword ? 'translate-x-5' : ''}`} />
                        </button>
                     </div>
                     <AnimatePresence>
                        {requirePassword && (
                           <motion.div initial={{ opacity: 0, height: 0 }} animate={{ opacity: 1, height: 'auto' }} exit={{ opacity: 0, height: 0 }} className="mt-3 pt-3 border-t border-gray-200 overflow-hidden">
                              <input 
                                 type="text" 
                                 placeholder="Set a strong password..." 
                                 value={transferPassword} 
                                 onChange={e => setTransferPassword(e.target.value)} 
                                 className="w-full bg-white border border-gray-200 rounded-xl px-4 py-3 text-sm font-bold focus:outline-none focus:border-purple-500 focus:ring-2 focus:ring-purple-500/20 transition-all" 
                              />
                           </motion.div>
                        )}
                     </AnimatePresence>
                  </div>
                  
                  {/* ECDH Guarantee */}
                  <div className="flex items-center justify-between p-4 bg-gray-50 rounded-2xl border border-gray-100">
                     <div className="flex items-center gap-3">
                        <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center"><Lock size={18} className="text-emerald-600" /></div>
                        <div>
                           <p className="text-sm font-extrabold text-gray-900">ECDH Ready</p>
                           <p className="text-[10px] font-bold text-gray-500">Awaiting nearby peer to generate keys...</p>
                        </div>
                     </div>
                     <CheckCircle2 size={20} className="text-emerald-500" fill="currentColor" />
                  </div>
               </div>

               <button onClick={() => navigate('discovery')} className="w-full py-4 bg-gray-900 text-white font-extrabold rounded-[24px] shadow-xl active:scale-95 transition-transform flex items-center justify-center gap-2">
                  <RadarIcon size={20} /> Scan Nearby Devices
               </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </ScreenTransition>
  );
};

const DeviceDiscoveryScreen = ({ navigate }) => {
  const [devices, setDevices] = useState([]);

  useEffect(() => {
    // Simulate finding Wi-Fi Direct / Bluetooth active peers nearby
    const t1 = setTimeout(() => setDevices(prev => [...prev, { id: 1, name: "Sarah's Mac", type: "laptop", status: "Active" }]), 1800);
    const t2 = setTimeout(() => setDevices(prev => [...prev, { id: 2, name: "David's Pixel 8", type: "phone", status: "Active" }]), 3500);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);

  return (
    <ScreenTransition className="bg-gray-950 text-white overflow-hidden flex flex-col">
       <div className="px-6 py-4 flex items-center justify-between z-10">
          <button onClick={() => navigate('files')} className="p-2 -ml-2 rounded-full hover:bg-gray-800 transition-colors">
            <ArrowLeft size={24} className="text-white" />
          </button>
          <div className="flex flex-col items-center">
             <h2 className="text-lg font-extrabold tracking-tight">Nearby Radar</h2>
             <span className="text-[10px] font-bold text-emerald-400 tracking-widest uppercase flex items-center gap-1"><Wifi size={10}/> Direct Active</span>
          </div>
          <div className="w-8"></div>
       </div>

       <div className="flex-1 flex flex-col items-center justify-center relative mt-[-40px]">
          {/* Animated Radar Sonar Rings */}
          {[0, 1, 2].map((i) => (
             <motion.div key={i} className="absolute w-40 h-40 bg-blue-500/10 rounded-full border border-blue-500/20"
                animate={{ scale: [1, 5], opacity: [0.8, 0] }}
                transition={{ duration: 4, repeat: Infinity, delay: i * 1.3, ease: "linear" }}
             />
          ))}

          {/* Central User Node */}
          <div className="relative z-10 w-24 h-24 bg-gray-900 rounded-full border-4 border-gray-800 flex items-center justify-center shadow-[0_0_40px_rgba(37,99,235,0.3)]">
             <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" className="w-full h-full bg-white rounded-full" />
             <div className="absolute -bottom-2 -right-2 w-8 h-8 bg-blue-600 text-white rounded-full border-2 border-gray-950 flex items-center justify-center">
                <RadarIcon size={14} />
             </div>
          </div>

          {/* Orbiting Found Devices */}
          <AnimatePresence>
             {devices.map((dev, i) => (
                <motion.div key={dev.id}
                   initial={{ scale: 0, opacity: 0, y: 20 }}
                   animate={{ scale: 1, opacity: 1, y: 0 }}
                   className={`absolute z-20 flex flex-col items-center cursor-pointer group ${i === 0 ? 'top-[20%] left-[20%]' : 'bottom-[25%] right-[15%]'}`}
                   onClick={() => navigate('transfer')}
                >
                   <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-[0_10px_30px_rgba(0,0,0,0.5)] mb-3 group-hover:scale-110 transition-transform duration-300 relative">
                      {dev.type === 'laptop' ? <Laptop size={30} className="text-gray-900" /> : <Smartphone size={30} className="text-gray-900" />}
                      <div className="absolute top-0 right-0 w-4 h-4 bg-emerald-500 border-2 border-white rounded-full animate-pulse"></div>
                   </div>
                   <div className="bg-gray-800/80 backdrop-blur-md border border-gray-700 px-3 py-1.5 rounded-xl shadow-lg flex flex-col items-center">
                      <span className="text-[11px] font-extrabold text-white whitespace-nowrap">{dev.name}</span>
                   </div>
                </motion.div>
             ))}
          </AnimatePresence>
       </div>

       <div className="absolute bottom-12 left-0 right-0 text-center z-20 flex flex-col items-center">
          <div className="bg-blue-900/30 border border-blue-800 text-blue-300 px-4 py-2 rounded-full text-xs font-bold flex items-center gap-2 mb-4 shadow-lg backdrop-blur-sm">
             <div className="w-2 h-2 rounded-full bg-blue-400 animate-pulse"></div>
             Scanning for active P2P nodes...
          </div>
          
          {/* New QR Scan Access from Redesign Board */}
          <button onClick={() => navigate('qr_scanner')} className="mt-2 flex items-center gap-2 text-[11px] font-extrabold text-white bg-white/10 hover:bg-white/20 px-4 py-2 rounded-xl backdrop-blur-md transition-colors border border-white/10">
             <ScanLine size={16} /> Scan QR to Connect
          </button>
       </div>
    </ScreenTransition>
  );
};

const TransferProgressScreen = ({ navigate }) => {
  const [phase, setPhase] = useState(0); 
  const [progress, setProgress] = useState(0);
  const [showToast, setShowToast] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  
  useEffect(() => {
    const seq = async () => {
      await new Promise(r => setTimeout(r, 1000)); setPhase(1); 
      await new Promise(r => setTimeout(r, 1500)); setPhase(2); 
      await new Promise(r => setTimeout(r, 1000)); setPhase(3); 
    };
    seq();
  }, []);

  useEffect(() => {
    if (phase === 3 && !isPaused) {
      const interval = setInterval(() => {
        setProgress(p => {
          if (p >= 100) { clearInterval(interval); setPhase(4); return 100; }
          return p + 0.8; 
        });
      }, 50);
      return () => clearInterval(interval);
    }
  }, [phase, isPaused]);

  const handleDisconnect = () => {
     setShowToast(true);
     setTimeout(() => {
         setShowToast(false);
         navigate('home');
     }, 1500); 
  };

  const phaseMessages = [
    "Generating local keypair...",
    "Exchanging public keys (Wi-Fi Direct)...",
    "Computing ECDH shared secret...",
    "Transferring encrypted chunks...",
    "Transfer Complete"
  ];

  return (
    <ScreenTransition className="bg-gray-950 text-white flex flex-col relative">
       {/* Disconnect Toast */}
       <AnimatePresence>
          {showToast && (
             <motion.div 
               initial={{ y: -100, opacity: 0 }} 
               animate={{ y: 0, opacity: 1 }} 
               exit={{ y: -100, opacity: 0 }}
               className="absolute top-6 left-1/2 -translate-x-1/2 z-50 bg-red-500 text-white px-5 py-3 rounded-full font-extrabold text-sm shadow-[0_10px_30px_rgba(239,68,68,0.4)] flex items-center gap-2 whitespace-nowrap"
             >
                <ServerOff size={18} />
                Connection Closed
             </motion.div>
          )}
       </AnimatePresence>

      <div className="px-6 py-4 flex items-center justify-between z-10 border-b border-gray-800">
         <h2 className="text-xl font-extrabold flex items-center gap-2">
            {phase < 3 ? 'Securing Channel' : phase === 4 ? 'Complete' : isPaused ? 'Paused' : 'Transferring'}
         </h2>
         {phase === 3 && !isPaused && <span className="text-xs font-bold bg-blue-900/50 text-blue-400 px-3 py-1 rounded-full border border-blue-800">120 MB/s</span>}
         {phase === 3 && isPaused && <span className="text-xs font-bold bg-yellow-900/50 text-yellow-400 px-3 py-1 rounded-full border border-yellow-800">0 MB/s</span>}
      </div>
      
      <div className="px-6 flex-1 flex flex-col h-full pt-8 pb-32">
        {/* Device Connection Graphic */}
        <div className="bg-gray-900 rounded-[32px] p-8 mb-6 flex items-center justify-between relative border border-gray-800 shadow-2xl">
           <div className="flex flex-col items-center z-10">
              <div className="w-16 h-16 rounded-full bg-gray-800 p-1 mb-3 border-2 border-gray-700">
                 <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" className="w-full h-full rounded-full bg-white" />
              </div>
              <span className="text-[13px] font-extrabold">Me</span>
           </div>

           <div className="flex-1 flex flex-col items-center px-4 relative z-10">
              {phase < 3 ? (
                <div className="flex flex-col items-center">
                   <Key size={24} className={`${phase === 2 ? 'text-emerald-400' : 'text-blue-400'} mb-2`} />
                   <div className="flex gap-1 mb-2 animate-pulse">
                      <div className="w-2 h-2 rounded-full bg-emerald-500"></div>
                      <div className="w-2 h-2 rounded-full bg-blue-500"></div>
                   </div>
                   <div className="text-[9px] font-bold text-gray-400 text-center uppercase tracking-widest">{phaseMessages[phase]}</div>
                </div>
              ) : (
                <div className="w-full relative">
                   <div className={`absolute -top-6 left-1/2 -translate-x-1/2 text-[10px] font-bold px-2 py-1 rounded-full border flex items-center gap-1 whitespace-nowrap transition-colors ${isPaused ? 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30' : 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30'}`}>
                      {isPaused ? <Pause size={10} /> : <Lock size={10} />} 
                      {isPaused ? 'Stream Paused' : 'Encrypted Stream'}
                   </div>
                   <div className="w-full h-2 bg-gray-800 rounded-full overflow-hidden shadow-inner">
                      {!isPaused && <motion.div className="absolute left-0 top-0 bottom-0 bg-gradient-to-r from-blue-500 to-emerald-400 w-full rounded-full" animate={{ x: ['-100%', '100%'] }} transition={{ duration: 0.8, repeat: Infinity, ease: "linear" }} />}
                      {isPaused && <div className="absolute left-0 top-0 bottom-0 bg-yellow-500 w-full rounded-full" />}
                   </div>
                </div>
              )}
           </div>

           <div className="flex flex-col items-center z-10">
              <div className="w-16 h-16 rounded-full bg-gray-800 p-1 mb-3 border-2 border-gray-700">
                 <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Mac" className="w-full h-full rounded-full bg-white" />
              </div>
              <span className="text-[13px] font-extrabold">Sarah</span>
           </div>
        </div>

        {/* Global Progress */}
        <div className="mb-6 px-2 transition-opacity duration-500" style={{ opacity: phase < 3 ? 0.3 : 1 }}>
           <div className="flex justify-between items-end mb-4">
              <h3 className="text-xl font-extrabold tracking-tight">Total Progress</h3>
              <span className={`text-4xl font-black tracking-tighter ${phase === 4 ? 'text-emerald-400' : isPaused ? 'text-yellow-500' : 'text-blue-500'}`}>{Math.floor(progress)}%</span>
           </div>
           <div className="w-full h-4 bg-gray-800 rounded-full overflow-hidden mb-2">
              <div className={`h-full rounded-full transition-all duration-200 relative ${phase === 4 ? 'bg-emerald-500' : isPaused ? 'bg-yellow-500' : 'bg-blue-600'}`} style={{ width: `${progress}%` }}></div>
           </div>
           <p className="text-xs text-gray-500 text-right font-bold">
               {phase === 4 ? 'All files verified and saved.' : isPaused ? 'Awaiting resume...' : `Scrambling chunk ${Math.floor(progress * 15)}...`}
           </p>
        </div>

        {/* Detailed File List from Redesign */}
        <div className="flex-1 overflow-y-auto space-y-3 mb-6 transition-opacity duration-500 px-2" style={{ opacity: phase < 3 ? 0.2 : 1 }}>
           {[
              { id: 1, name: "Vacation_Video.mp4", size: "1.2 GB", icon: Video, color: "text-purple-500", p: progress },
              { id: 2, name: "Project_Presentation.pdf", size: "12.4 MB", icon: FileText, color: "text-blue-500", p: progress > 10 ? Math.min((progress - 10) * 2, 100) : 0 },
              { id: 3, name: "Design_Assets.zip", size: "450 MB", icon: FolderOpen, color: "text-yellow-500", p: progress > 50 ? Math.min((progress - 50) * 3, 100) : 0 },
           ].map((file) => (
              <div key={file.id} className="bg-gray-900 rounded-2xl p-3 border border-gray-800 flex items-center gap-3">
                 <div className="w-10 h-10 bg-gray-800 rounded-xl flex items-center justify-center">
                    <file.icon size={18} className={file.color} />
                 </div>
                 <div className="flex-1 overflow-hidden">
                    <div className="flex justify-between items-center mb-1.5">
                       <p className="text-xs font-extrabold text-white truncate pr-2">{file.name}</p>
                       <span className="text-[9px] font-bold text-gray-500">{file.size}</span>
                    </div>
                    <div className="w-full h-1.5 bg-gray-800 rounded-full overflow-hidden">
                       <div className={`h-full rounded-full transition-all duration-300 ${file.p === 100 ? 'bg-emerald-500' : 'bg-blue-500'}`} style={{ width: `${file.p}%` }}></div>
                    </div>
                 </div>
                 <div className="w-8 flex justify-end">
                    {file.p === 100 ? <CheckCircle2 size={16} className="text-emerald-500" /> : <span className="text-[10px] font-bold text-gray-400">{Math.floor(file.p)}%</span>}
                 </div>
              </div>
           ))}
        </div>

        {/* Dynamic Action Buttons */}
        <div className="absolute bottom-0 left-0 right-0 p-6 bg-gray-950 z-40 flex flex-col gap-3 border-t border-gray-900">
            {phase === 4 ? (
               <>
                  <div className="flex justify-center space-x-3 mb-2">
                     <button onClick={() => navigate('files')} className="flex-1 py-4 rounded-[24px] bg-blue-600 text-white font-extrabold active:scale-95 transition-transform flex items-center justify-center gap-2 shadow-lg shadow-blue-900/50">
                        <Send size={18} /> Send More
                     </button>
                     <button onClick={() => navigate('history')} className="flex-1 py-4 rounded-[24px] bg-gray-800 text-white font-extrabold active:scale-95 transition-transform border border-gray-700 hover:bg-gray-700 flex items-center justify-center gap-2">
                        <Clock size={18} /> History
                     </button>
                  </div>
                  <button onClick={handleDisconnect} className="w-full py-3 rounded-full text-gray-500 font-bold text-sm hover:text-white transition-colors">
                     Disconnect & Close
                  </button>
               </>
            ) : phase === 3 ? (
               <div className="flex justify-center space-x-3">
                  <button onClick={() => setIsPaused(!isPaused)} className={`flex-1 py-4 rounded-[24px] font-extrabold active:scale-95 transition-transform flex items-center justify-center gap-2 shadow-lg ${isPaused ? 'bg-blue-600 text-white shadow-blue-900/50' : 'bg-yellow-600 text-white shadow-yellow-900/50'}`}>
                     {isPaused ? <Play size={18} fill="currentColor" /> : <Pause size={18} fill="currentColor" />}
                     {isPaused ? 'Resume' : 'Pause'}
                  </button>
                  <button onClick={handleDisconnect} className="flex-1 py-4 rounded-[24px] bg-gray-800 text-white font-extrabold active:scale-95 transition-transform border border-gray-700 hover:bg-gray-700 flex items-center justify-center gap-2 text-red-400">
                     <X size={18} /> Cancel
                  </button>
               </div>
            ) : (
               <button onClick={handleDisconnect} className="w-full py-4 rounded-[24px] bg-gray-900 text-white font-extrabold active:scale-95 transition-transform border border-gray-800 hover:bg-gray-800">
                  Cancel Handshake
               </button>
            )}
        </div>
      </div>
    </ScreenTransition>
  );
};

const ReceiveScreen = ({ navigate }) => {
  const [phase, setPhase] = useState('searching'); // searching, connecting, connected, prompting, unlocking
  const [showToast, setShowToast] = useState(false);
  const [toastConfig, setToastConfig] = useState({ message: '', type: 'success' });
  const [receivePassword, setReceivePassword] = useState('');
  useEffect(() => {
    let t1, t2, t3;
    t1 = setTimeout(() => setPhase('connecting'), 2000);
    t2 = setTimeout(() => {
      setPhase('connected');
      setToastConfig({ message: 'Connection Established', type: 'success' });
      setShowToast(true);
      setTimeout(() => setShowToast(false), 2500);
    }, 4000);
    t3 = setTimeout(() => setPhase('prompting'), 5500);

    return () => { clearTimeout(t1); clearTimeout(t2); clearTimeout(t3); };
  }, []);

  const handleDisconnect = () => {
     setToastConfig({ message: 'Connection Closed', type: 'error' });
     setShowToast(true);
     setTimeout(() => {
         setShowToast(false);
         navigate('home');
     }, 1500);
  };

  return (
    <ScreenTransition className="bg-gray-950 text-white overflow-hidden flex flex-col relative">
       {/* Connection Toast Notification */}
       <AnimatePresence>
          {showToast && (
             <motion.div 
               initial={{ y: -100, opacity: 0 }} 
               animate={{ y: 0, opacity: 1 }} 
               exit={{ y: -100, opacity: 0 }}
               className={`absolute top-6 left-1/2 -translate-x-1/2 z-50 text-white px-5 py-3 rounded-full font-extrabold text-sm shadow-xl flex items-center gap-2 whitespace-nowrap ${toastConfig.type === 'success' ? 'bg-emerald-500 shadow-emerald-500/40' : 'bg-red-500 shadow-red-500/40'}`}
             >
                {toastConfig.type === 'success' ? <CheckCircle2 size={18} /> : <ServerOff size={18} />}
                {toastConfig.message}
             </motion.div>
          )}
       </AnimatePresence>

       <div className="px-6 py-4 flex items-center justify-between z-10">
          <button onClick={handleDisconnect} className="p-2 -ml-2 rounded-full hover:bg-gray-800 transition-colors">
            <X size={24} className="text-white" />
          </button>
          <div className="flex flex-col items-center">
             <h2 className="text-lg font-extrabold tracking-tight">Receive Mode</h2>
             <span className="text-[10px] font-bold text-emerald-400 tracking-widest uppercase flex items-center gap-1"><Wifi size={10}/> Visible to Peers</span>
          </div>
          <div className="w-8"></div>
       </div>

       <div className="flex-1 flex flex-col items-center justify-center relative mt-[-40px]">
          {/* Animated Radar */}
          <AnimatePresence>
             {phase === 'searching' && [0, 1, 2].map((i) => (
                <motion.div key={i} className="absolute w-40 h-40 bg-emerald-500/10 rounded-full border border-emerald-500/20"
                   animate={{ scale: [1, 5], opacity: [0.8, 0] }}
                   transition={{ duration: 4, repeat: Infinity, delay: i * 1.3, ease: "linear" }}
                   exit={{ opacity: 0 }}
                />
             ))}
          </AnimatePresence>

          {/* User Node */}
          <div className="relative z-10 w-24 h-24 bg-gray-900 rounded-full border-4 border-gray-800 flex items-center justify-center shadow-[0_0_40px_rgba(16,185,129,0.3)]">
             <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" className="w-full h-full bg-white rounded-full" />
             <div className="absolute -bottom-2 -right-2 w-8 h-8 bg-emerald-600 text-white rounded-full border-2 border-gray-950 flex items-center justify-center">
                <Download size={14} />
             </div>
          </div>

          {/* Incoming Connection UI */}
          {phase !== 'searching' && (
             <motion.div 
                initial={{ scale: 0, opacity: 0, y: 50 }}
                animate={{ scale: 1, opacity: 1, y: 0 }}
                className="absolute top-[60%] flex flex-col items-center z-20"
             >
                <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center shadow-[0_10px_30px_rgba(0,0,0,0.5)] mb-3">
                   <Laptop size={30} className="text-gray-900" />
                   <div className="absolute top-0 right-0 w-4 h-4 bg-blue-500 border-2 border-white rounded-full animate-pulse"></div>
                </div>
                <div className="bg-blue-600 border border-blue-500 px-4 py-2 rounded-xl shadow-lg flex flex-col items-center">
                   <span className="text-[11px] font-extrabold text-white whitespace-nowrap">Sarah's Mac</span>
                   {phase === 'connecting' && <span className="text-[9px] text-blue-200 mt-1 font-bold">Negotiating Handshake...</span>}
                </div>
             </motion.div>
          )}
       </div>

       <div className="absolute bottom-12 left-0 right-0 text-center z-10 flex flex-col items-center">
          {phase === 'searching' ? (
            <>
               <div className="bg-emerald-900/30 border border-emerald-800 text-emerald-300 px-4 py-2 rounded-full text-xs font-bold flex items-center gap-2 mb-4 shadow-lg backdrop-blur-sm">
                  <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></div>
                  Waiting for sender...
               </div>
               <p className="text-[10px] text-gray-500 font-bold uppercase tracking-widest">Keep screen on</p>
            </>
          ) : (
            <p className="text-[10px] text-gray-500 font-bold uppercase tracking-widest">
               {phase === 'prompting' ? 'Awaiting your approval' : 'Establishing direct link'}
            </p>
          )}
       </div>

       {/* File Acceptance Modal */}
       <AnimatePresence>
          {phase === 'prompting' && (
             <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} transition={{ type: "spring", damping: 25, stiffness: 200 }} className="absolute bottom-0 left-0 right-0 bg-white rounded-t-[40px] p-6 shadow-[0_-20px_50px_rgba(0,0,0,0.5)] border-t border-gray-200 z-50 text-gray-900">
                <div className="flex justify-between items-start mb-6">
                   <div>
                      <h3 className="text-xl font-black tracking-tight flex items-center gap-2">
                         <Download className="text-blue-600" size={24} /> Incoming File
                      </h3>
                      <p className="text-xs font-bold text-gray-500 mt-1">Sarah's Mac wants to send you data.</p>
                   </div>
                   <div className="w-10 h-10 rounded-full bg-blue-50 flex items-center justify-center">
                      <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Mac" className="w-8 h-8 rounded-full" />
                   </div>
                </div>

                <div className="bg-gray-50 rounded-2xl p-4 border border-gray-100 mb-6 flex items-center gap-4 relative overflow-hidden">
                   <div className="absolute -right-4 -top-4 w-16 h-16 bg-purple-100 rounded-full blur-xl opacity-50"></div>
                   <div className="w-12 h-12 bg-white rounded-xl border border-gray-200 flex items-center justify-center shadow-sm relative z-10">
                      <Video size={24} className="text-purple-500" />
                   </div>
                   <div className="flex-1 relative z-10">
                      <div className="flex items-center gap-2">
                         <h4 className="text-sm font-extrabold text-gray-900 truncate pr-4">Vacation_Edit_Final.mp4</h4>
                      </div>
                      <p className="text-xs font-bold text-gray-500 mt-1">1.2 GB • Video</p>
                   </div>
                   <div className="absolute top-2 right-2 text-purple-500 bg-purple-50 p-1.5 rounded-lg border border-purple-100">
                      <Lock size={14} />
                   </div>
                </div>

                <div className="flex gap-4">
                   <button onClick={handleDisconnect} className="flex-1 py-4 bg-gray-100 text-gray-900 font-extrabold rounded-2xl hover:bg-gray-200 transition-colors">Decline</button>
                   <button onClick={() => setPhase('unlocking')} className="flex-1 py-4 bg-blue-600 text-white font-extrabold rounded-2xl shadow-lg shadow-blue-600/30 hover:bg-blue-700 transition-colors flex items-center justify-center gap-2">
                      <Download size={18} /> Accept
                   </button>
                </div>
             </motion.div>
          )}

          {phase === 'unlocking' && (
             <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} transition={{ type: "spring", damping: 25, stiffness: 200 }} className="absolute bottom-0 left-0 right-0 bg-white rounded-t-[40px] p-6 shadow-[0_-20px_50px_rgba(0,0,0,0.5)] border-t border-gray-200 z-50 text-gray-900">
                <div className="flex justify-between items-start mb-6">
                   <div>
                      <h3 className="text-xl font-black tracking-tight flex items-center gap-2">
                         <Lock className="text-purple-600" size={24} /> Password Required
                      </h3>
                      <p className="text-xs font-bold text-gray-500 mt-1">The sender protected this transfer with a password.</p>
                   </div>
                </div>
                
                <div className="mb-6">
                   <input 
                      type="password" 
                      placeholder="Enter password to unlock..." 
                      value={receivePassword}
                      onChange={e => setReceivePassword(e.target.value)}
                      className="w-full bg-gray-50 border-2 border-gray-200 rounded-2xl px-5 py-4 text-sm font-bold focus:outline-none focus:border-purple-500 transition-colors" 
                   />
                </div>

                <div className="flex gap-4">
                   <button onClick={handleDisconnect} className="flex-1 py-4 bg-gray-100 text-gray-900 font-extrabold rounded-2xl hover:bg-gray-200 transition-colors">Cancel</button>
                   <button 
                      onClick={() => receivePassword ? navigate('transfer') : null} 
                      className={`flex-1 py-4 font-extrabold rounded-2xl transition-all flex items-center justify-center gap-2 ${receivePassword ? 'bg-purple-600 text-white shadow-lg shadow-purple-600/30 active:scale-95' : 'bg-gray-200 text-gray-400 cursor-not-allowed'}`}
                   >
                      <Key size={18} /> Unlock Stream
                   </button>
                </div>
             </motion.div>
          )}
       </AnimatePresence>
    </ScreenTransition>
  );
};

const DiscoverScreen = ({ navigate }) => {
  const [activeTab, setActiveTab] = useState('Featured');

  return (
    <ScreenTransition className="bg-gray-50">
      <div className="px-6 py-4 pt-6 flex items-center justify-between sticky top-0 bg-gray-50/90 backdrop-blur-md z-20">
         <h2 className="text-2xl font-black text-gray-900 tracking-tight">Discover</h2>
         <button className="p-2.5 rounded-full bg-white shadow-sm border border-gray-100 text-gray-600 hover:text-blue-600 transition-colors">
            <Search size={20} />
         </button>
      </div>

      <div className="px-6 pb-2 border-b border-gray-200 sticky top-[72px] bg-gray-50/90 backdrop-blur-md z-20">
         <div className="flex gap-2">
            {['Featured', 'News Feed', 'Videos'].map((tab) => (
               <button 
                  key={tab} 
                  onClick={() => setActiveTab(tab)}
                  className={`px-4 py-2 rounded-full text-xs font-extrabold transition-all duration-300 ${activeTab === tab ? 'bg-blue-600 text-white shadow-md' : 'bg-white text-gray-500 border border-gray-200'}`}
               >
                  {tab}
               </button>
            ))}
         </div>
      </div>

      <div className="p-6 overflow-y-auto pb-32 space-y-8">
         {activeTab === 'Featured' && (
            <>
               <div>
                  <h3 className="text-sm font-extrabold text-gray-900 mb-4 flex items-center gap-2">
                     <Gift size={18} className="text-purple-500" /> Editor's Picks
                  </h3>
                  <div className="grid grid-cols-3 gap-4">
                     {MOCK_FEATURED_APPS.map((app) => (
                        <div key={app.id} className="bg-white rounded-2xl p-4 flex flex-col items-center border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
                           <img src={app.icon} alt={app.name} className="w-14 h-14 rounded-2xl mb-3 shadow-sm" />
                           <h4 className="text-xs font-extrabold text-gray-900 line-clamp-1 text-center w-full">{app.name}</h4>
                           <span className="text-[10px] text-gray-500 font-bold mb-3">{app.size}</span>
                           <button className="w-full py-1.5 bg-blue-50 text-blue-600 text-[11px] font-extrabold rounded-lg hover:bg-blue-100 transition-colors">GET</button>
                        </div>
                     ))}
                  </div>
               </div>

               <div>
                  <h3 className="text-sm font-extrabold text-gray-900 mb-4 flex items-center gap-2">
                     <Grid size={18} className="text-blue-500" /> Trending Utilities
                  </h3>
                  <div className="space-y-3">
                     {MOCK_APPS.slice(0, 3).map((app) => (
                        <div key={app.id} className="flex items-center justify-between bg-white p-3 rounded-2xl border border-gray-100 shadow-sm">
                           <div className="flex items-center gap-3">
                              <img src={app.icon} className="w-12 h-12 rounded-xl" />
                              <div>
                                 <h4 className="text-sm font-extrabold text-gray-900">{app.name}</h4>
                                 <p className="text-[10px] font-bold text-gray-500 flex items-center gap-1">
                                    <StarIcon size={10} className="text-yellow-500" /> 4.8 • {app.size}
                                 </p>
                              </div>
                           </div>
                           <button className="px-4 py-2 bg-blue-600 text-white text-xs font-extrabold rounded-xl shadow-md shadow-blue-600/20 active:scale-95">Download</button>
                        </div>
                     ))}
                  </div>
               </div>
            </>
         )}

         {activeTab === 'News Feed' && (
            <div className="space-y-4">
               {MOCK_DISCOVER_NEWS.map((news) => (
                  <div key={news.id} className="bg-white rounded-[24px] overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-all">
                     <img src={news.image} alt="News" className="w-full h-40 object-cover" />
                     <div className="p-4">
                        <span className="text-[10px] font-extrabold text-blue-600 uppercase tracking-widest mb-1 block">{news.source}</span>
                        <h4 className="text-sm font-extrabold text-gray-900 leading-snug mb-2">{news.title}</h4>
                        <span className="text-xs text-gray-500 font-bold flex items-center gap-1"><Clock size={12}/> {news.time}</span>
                     </div>
                  </div>
               ))}
            </div>
         )}

         {activeTab === 'Videos' && (
            <div className="space-y-4">
               {[1, 2, 3].map((i) => (
                  <div key={i} className="bg-white rounded-[24px] overflow-hidden border border-gray-100 shadow-sm relative group cursor-pointer">
                     <img src={`https://images.unsplash.com/photo-${1500000000000 + i * 100000}?w=400&h=200&fit=crop`} alt="Video" className="w-full h-48 object-cover opacity-90 group-hover:scale-105 transition-transform duration-500" />
                     <div className="absolute inset-0 bg-black/20 flex items-center justify-center">
                        <div className="w-12 h-12 bg-white/30 backdrop-blur-md rounded-full flex items-center justify-center text-white border border-white/50 group-hover:scale-110 transition-transform">
                           <PlaySquare size={24} fill="currentColor" />
                        </div>
                     </div>
                     <div className="absolute bottom-2 right-2 bg-black/60 backdrop-blur-sm text-white text-[10px] font-bold px-2 py-1 rounded-md">
                        {i}:45
                     </div>
                  </div>
               ))}
            </div>
         )}
      </div>
    </ScreenTransition>
  );
};

const ProfileScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-gray-50">
      <div className="px-6 py-4 pt-6 flex justify-between items-center bg-gray-50 sticky top-0 z-20">
         <h2 className="text-2xl font-black text-gray-900 tracking-tight">Profile</h2>
         <button onClick={() => navigate('settings')} className="p-2.5 rounded-full bg-white shadow-sm border border-gray-100 hover:bg-gray-100 transition-colors text-gray-600">
           <Settings size={22} />
         </button>
      </div>

      <div className="px-6 overflow-y-auto pb-32 space-y-6">
         <div className="flex items-center gap-4 bg-white p-5 rounded-[32px] border border-gray-100 shadow-sm">
            <div className="w-16 h-16 bg-blue-600 rounded-full flex items-center justify-center p-[2px] relative shadow-md">
              <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" alt="Profile" className="w-full h-full bg-white rounded-full object-cover" />
              <div className="absolute bottom-0 right-0 w-4 h-4 bg-emerald-500 border-[3px] border-white rounded-full"></div>
            </div>
            <div className="flex flex-col">
               <h3 className="text-xl font-extrabold text-gray-900">Alex Walker</h3>
               <div className="flex items-center gap-2 mt-1">
                  <span className="text-[11px] font-extrabold text-gray-500">ID: SH-9482X</span>
                  <div className="flex bg-yellow-50 rounded-full px-2 py-0.5 items-center space-x-1 border border-yellow-100">
                    <Crown size={12} className="text-yellow-600" fill="currentColor" />
                    <span className="text-[10px] font-black text-yellow-700">PRO</span>
                  </div>
               </div>
            </div>
         </div>

         <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-[32px] p-6 shadow-xl relative overflow-hidden text-white">
             <div className="absolute top-0 right-0 p-4 opacity-10"><HardDrive size={100} /></div>
             <div className="relative z-10">
                <div className="flex justify-between items-end mb-4">
                   <div>
                      <h4 className="text-sm font-extrabold text-gray-300 uppercase tracking-widest flex items-center gap-2">
                         <HardDrive size={16} /> Internal Storage
                      </h4>
                      <p className="text-2xl font-black mt-1">75% <span className="text-sm font-bold text-gray-400">Used</span></p>
                   </div>
                   <button onClick={() => navigate('clean')} className="text-xs font-bold bg-white/20 hover:bg-white/30 backdrop-blur-md px-4 py-2 rounded-xl transition-colors">Clean Up</button>
                </div>
                
                <div className="w-full h-3 bg-gray-700 rounded-full overflow-hidden mb-3 shadow-inner">
                   <motion.div initial={{ width: 0 }} animate={{ width: '75%' }} transition={{ duration: 1, ease: 'easeOut' }} className="h-full bg-gradient-to-r from-blue-500 to-emerald-400 rounded-full" />
                </div>
                
                <div className="flex justify-between text-xs font-bold text-gray-400">
                   <span>96 GB Used</span>
                   <span>128 GB Total</span>
                </div>
             </div>
         </div>

         <div className="bg-white rounded-[32px] p-2 shadow-sm border border-gray-100">
            {[
               { icon: SmartphoneCharging, label: "Phone Replicate", sub: "Clone data to a new device", color: "text-purple-500", bg: "bg-purple-50", route: 'replicate' },
               { icon: Globe, label: "WebShare", sub: "Share without network via browser", color: "text-blue-500", bg: "bg-blue-50", route: 'webshare' },
               { icon: Users, label: "Invite Friends", sub: "QR Code & Bluetooth Share", color: "text-emerald-500", bg: "bg-emerald-50", route: 'invite' },
               { icon: BarChart3, label: "Transfer Analytics", sub: "View your sharing history stats", color: "text-orange-500", bg: "bg-orange-50", route: 'analytics' },
               { icon: FolderOpen, label: "My Files", sub: "Received content & Downloads", color: "text-gray-500", bg: "bg-gray-100", route: 'myfiles' },
            ].map((item, i) => (
               <div key={i} onClick={() => navigate(item.route)} className="flex items-center justify-between p-3 rounded-2xl hover:bg-gray-50 cursor-pointer transition-colors group">
                  <div className="flex items-center gap-4">
                     <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${item.bg}`}>
                        <item.icon size={20} className={item.color} />
                     </div>
                     <div>
                        <h4 className="text-sm font-extrabold text-gray-900 group-hover:text-blue-600 transition-colors">{item.label}</h4>
                        <p className="text-[11px] font-bold text-gray-500">{item.sub}</p>
                     </div>
                  </div>
                  <ChevronRight size={18} className="text-gray-400 mr-2" />
               </div>
            ))}
         </div>
      </div>
    </ScreenTransition>
  );
};

const HistoryScreen = ({ navigate }) => {
  const [history, setHistory] = useState(RECENT_TRANSFERS);
  const [revokeConfirmId, setRevokeConfirmId] = useState(null);

  const confirmRevoke = (id) => setRevokeConfirmId(id);

  const executeRevoke = () => {
     setHistory(history.map(item => item.id === revokeConfirmId ? { ...item, status: 'revoked' } : item));
     setRevokeConfirmId(null);
  };

  return (
    <ScreenTransition className="bg-white relative">
      <ScreenHeader title="Transfer History" onBack={() => navigate('home')} />
      <div className="p-6 overflow-y-auto pb-32 space-y-4">
        <p className="text-xs font-bold text-gray-500 mb-2">Logged locally on this device.</p>
        
        {history.map((file) => (
          <div key={file.id} className={`flex flex-col p-4 rounded-2xl border transition-colors ${file.status === 'revoked' ? 'bg-red-50/50 border-red-100' : 'bg-gray-50 border-gray-100'}`}>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center space-x-3">
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center border ${file.status === 'revoked' ? 'bg-red-100 border-red-200' : 'bg-white border-gray-200'}`}>
                   {file.status === 'revoked' ? <XOctagon size={18} className="text-red-500" /> : <FileText size={18} className="text-blue-500" />}
                </div>
                <div>
                  <p className={`font-extrabold text-sm max-w-[150px] truncate ${file.status === 'revoked' ? 'text-red-900 line-through' : 'text-gray-900'}`}>{file.name}</p>
                  <div className="flex items-center text-[10px] text-gray-500 font-bold space-x-2 mt-0.5">
                    <span>{file.size}</span><span>•</span><span>{file.time}</span>
                  </div>
                </div>
              </div>
              
              {file.status === 'active' && file.expires ? (
                 <button onClick={() => confirmRevoke(file.id)} className="text-xs font-bold bg-red-100 text-red-600 px-3 py-1.5 rounded-lg border border-red-200 hover:bg-red-200 transition-colors flex items-center gap-1 active:scale-95">
                    <EyeOff size={12}/> Revoke Now
                 </button>
              ) : file.status === 'revoked' ? (
                 <span className="text-[10px] font-bold text-red-500 bg-red-50 px-2 py-1 rounded flex items-center gap-1"><CheckCircle2 size={10}/> Killed</span>
              ) : (
                 <button className="text-xs font-bold text-gray-500 bg-white px-3 py-1.5 rounded-lg border border-gray-200">View</button>
              )}
            </div>
            
            {file.status === 'active' && (
              <div className="bg-white p-2 rounded-xl border border-gray-100 flex items-center justify-between mt-1">
                 <span className="text-[10px] font-bold text-gray-500 flex items-center gap-1"><Lock size={10}/> Sent to Sarah's Mac</span>
                 <span className="text-[10px] font-bold text-orange-500 flex items-center gap-1"><Timer size={10}/> Expires in 21h 14m</span>
              </div>
            )}
          </div>
        ))}
      </div>

      <AnimatePresence>
        {revokeConfirmId && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex flex-col justify-end">
            <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} transition={{ type: "spring", damping: 25, stiffness: 200 }} className="bg-white rounded-t-[40px] p-8 shadow-2xl border-t border-gray-200">
               <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mb-6 border-4 border-red-50">
                  <AlertTriangle size={32} className="text-red-600" />
               </div>
               
               <h3 className="text-2xl font-black text-gray-900 tracking-tight mb-2">Execute Remote Kill?</h3>
               <p className="text-sm text-gray-500 font-medium mb-6 leading-relaxed">
                  This queues an encrypted kill signal. If the receiver is offline, the signal waits and destroys the file data the instant their app next opens.
               </p>

               <div className="flex gap-4">
                  <button onClick={() => setRevokeConfirmId(null)} className="flex-1 py-4 bg-gray-100 text-gray-900 font-extrabold rounded-2xl hover:bg-gray-200 transition-colors">Cancel</button>
                  <button onClick={executeRevoke} className="flex-1 py-4 bg-red-600 text-white font-extrabold rounded-2xl shadow-lg shadow-red-600/30 hover:bg-red-700 transition-colors flex items-center justify-center gap-2">
                     <XOctagon size={18} /> Send Kill Signal
                  </button>
               </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </ScreenTransition>
  );
};

const AnalyticsScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-gray-50">
       <ScreenHeader title="Analytics" subtitle="Calculated from local history" onBack={() => navigate('profile')} />
       
       <div className="p-6 overflow-y-auto pb-32">
          <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-[32px] p-6 mb-6 shadow-xl relative overflow-hidden text-white">
             <div className="absolute top-0 right-0 p-6 opacity-10"><Activity size={100} /></div>
             <p className="text-gray-400 font-extrabold text-xs uppercase tracking-widest mb-1 relative z-10">Total Transferred</p>
             <h2 className="text-4xl font-black tracking-tighter mb-6 relative z-10">214.5 <span className="text-xl text-gray-400">GB</span></h2>
             
             <div className="flex gap-4 relative z-10">
                <div className="flex-1 bg-white/10 rounded-2xl p-4 backdrop-blur-sm">
                   <div className="flex items-center gap-2 text-emerald-400 mb-1"><Send size={14} /> <span className="text-xs font-bold">Sent</span></div>
                   <p className="text-xl font-bold">142 GB</p>
                </div>
                <div className="flex-1 bg-white/10 rounded-2xl p-4 backdrop-blur-sm">
                   <div className="flex items-center gap-2 text-blue-400 mb-1"><Download size={14} /> <span className="text-xs font-bold">Received</span></div>
                   <p className="text-xl font-bold">72.5 GB</p>
                </div>
             </div>
          </div>

          <div className="bg-white rounded-[32px] p-6 shadow-sm border border-gray-100 mb-6">
             <h3 className="text-sm font-extrabold text-gray-900 mb-6">Weekly Activity</h3>
             <div className="flex items-end justify-between h-40 gap-2 mb-4">
                {[40, 85, 30, 100, 60, 20, 75].map((val, i) => (
                   <div key={i} className="w-full flex flex-col items-center gap-2 group">
                      <div className="w-full bg-blue-50 rounded-t-lg relative flex items-end justify-center h-32 group-hover:bg-blue-100 transition-colors">
                         <motion.div initial={{ height: 0 }} animate={{ height: `${val}%` }} transition={{ duration: 1, delay: i*0.1 }} className="w-full bg-blue-500 rounded-t-lg"></motion.div>
                      </div>
                      <span className="text-[10px] font-bold text-gray-400 uppercase">{'SMTWTFS'[i]}</span>
                   </div>
                ))}
             </div>
             <div className="flex justify-between items-center pt-4 border-t border-gray-100">
                <div>
                   <p className="text-[10px] font-bold text-gray-500 uppercase">Avg Speed</p>
                   <p className="text-sm font-extrabold text-gray-900">68 MB/s</p>
                </div>
                <div className="text-right">
                   <p className="text-[10px] font-bold text-gray-500 uppercase">Tech Used</p>
                   <p className="text-sm font-extrabold text-gray-900">80% Wi-Fi Direct</p>
                </div>
             </div>
          </div>
       </div>
    </ScreenTransition>
  );
};

const WorkspaceScreen = ({ navigate }) => {
  const [modalMode, setModalMode] = useState(null); 
  const [certGenerating, setCertGenerating] = useState(false);
  const [joinTab, setJoinTab] = useState('code');
  const [joinInput, setJoinInput] = useState('');
  const [copied, setCopied] = useState('');

  const handleCreate = () => { setModalMode('create'); setCertGenerating(true); setTimeout(() => setCertGenerating(false), 2000); };
  const handleJoin = () => { setModalMode('join'); setJoinTab('code'); setJoinInput(''); };

  const copyToClipboard = (text, type) => {
     navigator.clipboard.writeText(text); setCopied(type); setTimeout(() => setCopied(''), 2000);
  };

  return (
    <ScreenTransition className="bg-gray-50 relative">
       <ScreenHeader title="Local Workspaces" subtitle="Serverless shared folders" onBack={() => navigate('home')} />
       <div className="p-6 overflow-y-auto pb-32">
          <div className="flex gap-3 mb-8">
             <button onClick={handleCreate} className="flex-1 bg-blue-600 text-white p-4 rounded-2xl shadow-lg shadow-blue-500/20 flex flex-col items-center justify-center gap-2 active:scale-95 transition-transform">
                <div className="bg-white/20 p-2 rounded-full"><Users size={20} /></div>
                <span className="font-extrabold text-sm">Create Room</span>
             </button>
             <button onClick={handleJoin} className="flex-1 bg-white border border-gray-200 text-gray-900 p-4 rounded-2xl shadow-sm flex flex-col items-center justify-center gap-2 hover:bg-gray-50 active:scale-95 transition-all">
                <div className="bg-gray-100 p-2 rounded-full"><QrCode size={20} /></div>
                <span className="font-extrabold text-sm">Join Room</span>
             </button>
          </div>

          <h3 className="text-sm font-extrabold text-gray-900 mb-4 px-1">Your Active Spaces</h3>

          <div className="bg-white rounded-[32px] p-6 shadow-sm border border-gray-100 mb-6 relative overflow-hidden">
             <div className="absolute top-0 right-0 w-32 h-32 bg-purple-50 rounded-full blur-3xl"></div>
             
             <div className="flex justify-between items-start mb-6 relative z-10">
                <div>
                   <div className="flex items-center gap-2 mb-1">
                      <div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                      <span className="text-xs font-bold text-emerald-600 uppercase tracking-widest">Active Now</span>
                   </div>
                   <h2 className="text-2xl font-black text-gray-900 tracking-tight">Design Team</h2>
                   <p className="text-xs text-gray-500 font-bold mt-1">P2P Network • No Cloud</p>
                </div>
             </div>

             <div className="space-y-4 relative z-10">
                <h3 className="text-xs font-extrabold text-gray-400 uppercase tracking-widest flex justify-between items-center">
                  Verified Members (3)
                  <ShieldCheck size={14} className="text-emerald-500" />
                </h3>
                
                <div className="flex items-center justify-between bg-gray-50 p-3 rounded-2xl border border-gray-100">
                   <div className="flex items-center gap-3">
                      <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" className="w-10 h-10 rounded-full bg-white border border-gray-200" />
                      <div>
                         <p className="text-sm font-extrabold text-gray-900">Alex (You)</p>
                         <p className="text-[10px] font-bold text-gray-500 flex items-center gap-1"><FingerprintIcon size={10}/> Holds Root Private Key</p>
                      </div>
                   </div>
                   <span className="text-[10px] font-bold bg-purple-100 text-purple-700 px-2 py-1 rounded-md border border-purple-200">Admin</span>
                </div>

                <div className="flex items-center justify-between bg-gray-50 p-3 rounded-2xl border border-gray-100">
                   <div className="flex items-center gap-3">
                      <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Sarah" className="w-10 h-10 rounded-full bg-white border border-gray-200" />
                      <div>
                         <p className="text-sm font-extrabold text-gray-900">Sarah</p>
                         <p className="text-[10px] font-bold text-emerald-600 flex items-center gap-1"><ShieldCheck size={10}/> Cert Verified by Admin</p>
                      </div>
                   </div>
                   <span className="text-[10px] font-bold bg-blue-100 text-blue-700 px-2 py-1 rounded-md border border-blue-200">Editor</span>
                </div>
             </div>
          </div>
       </div>

       <AnimatePresence>
          {modalMode && (
             <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 z-50 bg-black/60 backdrop-blur-sm flex flex-col justify-end">
                <motion.div initial={{ y: "100%" }} animate={{ y: 0 }} exit={{ y: "100%" }} transition={{ type: "spring", damping: 25, stiffness: 200 }} className="bg-white rounded-t-[40px] p-6 shadow-2xl border-t border-gray-200 pb-12">
                   <div className="flex justify-between items-center mb-6 px-2">
                      <h3 className="text-xl font-extrabold text-gray-900 flex items-center gap-2">
                         {modalMode === 'create' ? <Key size={24} className="text-purple-500" /> : <ShieldCheck size={24} className="text-blue-500" />}
                         {modalMode === 'create' ? 'Room Created' : 'Join Room'}
                      </h3>
                      <button onClick={() => setModalMode(null)} className="w-8 h-8 bg-gray-100 rounded-full flex items-center justify-center text-gray-600"><X size={18} /></button>
                   </div>
                   
                   {certGenerating ? (
                      <div className="py-16 flex flex-col items-center">
                         <div className={`w-14 h-14 border-4 border-gray-100 rounded-full animate-spin mb-4 ${modalMode === 'create' ? 'border-t-purple-500' : 'border-t-blue-500'}`}></div>
                         <p className="text-sm font-extrabold text-gray-900">
                             {modalMode === 'create' ? 'Signing Certificate...' : 'Verifying Admin Signature...'}
                         </p>
                      </div>
                   ) : modalMode === 'create' ? (
                      <div className="flex flex-col items-center">
                         <div className="bg-gray-50 p-4 rounded-3xl border border-gray-200 mb-6 flex flex-col items-center shadow-inner w-full max-w-[250px]">
                            <p className="text-xs font-bold text-gray-500 uppercase tracking-widest mb-3">Ask them to scan</p>
                            <QrCode size={160} className="text-gray-900" />
                         </div>

                         <div className="w-full space-y-3">
                            <div className="w-full bg-white rounded-2xl p-3 flex items-center justify-between border border-gray-200 shadow-sm">
                               <div>
                                  <p className="text-[10px] font-bold text-gray-500 uppercase tracking-wider">Room Code</p>
                                  <p className="text-lg font-black tracking-widest text-gray-900">A8J-9P2</p>
                               </div>
                               <button onClick={() => copyToClipboard('A8J-9P2', 'code')} className="w-10 h-10 bg-blue-50 rounded-xl flex items-center justify-center text-blue-600 hover:bg-blue-100 transition-colors">
                                  {copied === 'code' ? <CheckCircle2 size={18}/> : <Copy size={18}/>}
                               </button>
                            </div>
                         </div>
                      </div>
                   ) : (
                      <div className="flex flex-col">
                         <div className="flex bg-gray-100 p-1.5 rounded-[20px] mb-6">
                            <button onClick={() => setJoinTab('code')} className={`flex-1 py-2.5 text-xs font-extrabold rounded-2xl transition-all ${joinTab === 'code' ? 'bg-white shadow-sm text-blue-600' : 'text-gray-500 hover:text-gray-700'}`}>Code / Link</button>
                            <button onClick={() => setJoinTab('qr')} className={`flex-1 py-2.5 text-xs font-extrabold rounded-2xl transition-all ${joinTab === 'qr' ? 'bg-white shadow-sm text-blue-600' : 'text-gray-500 hover:text-gray-700'}`}>Scan QR</button>
                         </div>

                         {joinTab === 'code' ? (
                            <div className="mb-8">
                               <input type="text" placeholder="e.g. A8J-9P2" className="w-full bg-gray-50 border-2 border-gray-200 rounded-[20px] px-5 py-4 text-sm font-bold focus:outline-none focus:border-blue-500 transition-colors" value={joinInput} onChange={(e) => setJoinInput(e.target.value)} />
                            </div>
                         ) : (
                            <div className="mb-8 flex flex-col items-center">
                               <div className="w-56 h-56 bg-gray-900 rounded-[32px] relative overflow-hidden flex items-center justify-center shadow-inner">
                                  <Camera size={40} className="text-white/40" />
                               </div>
                            </div>
                         )}

                         <button onClick={() => setModalMode(null)} className="w-full py-4 bg-blue-600 text-white font-extrabold rounded-[24px] shadow-lg shadow-blue-600/30 active:scale-95 transition-transform flex justify-center items-center gap-2">
                            <ShieldCheck size={20} /> Request Verification
                         </button>
                      </div>
                   )}
                </motion.div>
             </motion.div>
          )}
       </AnimatePresence>
    </ScreenTransition>
  );
};

const AutoSyncScreen = ({ navigate }) => {
  const [enabled, setEnabled] = useState(true);

  return (
    <ScreenTransition className="bg-gray-50">
       <ScreenHeader title="Auto-Sync Rules" subtitle="Background diff checking" onBack={() => navigate('home')} />
       <div className="p-6 overflow-y-auto pb-32">
          <div className="flex items-center justify-between bg-blue-600 rounded-[28px] p-6 mb-8 text-white shadow-lg shadow-blue-500/20">
             <div>
                <h3 className="text-lg font-black tracking-tight mb-1">OS Scheduler</h3>
                <p className="text-xs font-medium text-blue-200 max-w-[200px]">Wakes app only on condition match. No battery drain.</p>
             </div>
             <button onClick={() => setEnabled(!enabled)} className={`w-14 h-8 rounded-full p-1 transition-colors ${enabled ? 'bg-white' : 'bg-blue-400'}`}>
                <motion.div className={`w-6 h-6 rounded-full shadow-md ${enabled ? 'bg-blue-600' : 'bg-white'}`} animate={{ x: enabled ? 24 : 0 }} />
             </button>
          </div>

          <div className={`transition-opacity ${enabled ? 'opacity-100' : 'opacity-50 pointer-events-none'}`}>
             <h3 className="text-sm font-extrabold text-gray-900 uppercase tracking-widest mb-4">Active Rules</h3>
             <div className="bg-white rounded-[24px] p-5 border border-gray-100 shadow-sm relative overflow-hidden">
                <div className="flex justify-between items-start mb-4">
                   <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-gray-50 rounded-xl flex items-center justify-center border border-gray-200"><Camera size={18} className="text-gray-900"/></div>
                      <div>
                         <h4 className="text-sm font-extrabold text-gray-900">Camera Roll</h4>
                         <p className="text-[10px] font-bold text-gray-500">Syncs fingerprint diffs only</p>
                      </div>
                   </div>
                </div>
                <div className="bg-gray-50 rounded-xl p-3 flex flex-col gap-2">
                   <div className="flex items-center gap-2 text-xs font-bold text-gray-700">
                      <span className="text-gray-400">IF connected to:</span>
                      <span className="bg-white px-2 py-0.5 rounded shadow-sm border border-gray-200"><Wifi size={10} className="inline mr-1"/> Home_5G</span>
                   </div>
                </div>
             </div>
          </div>
       </div>
    </ScreenTransition>
  );
};

const ReplicateScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-white">
      <ScreenHeader title="Phone Replicate" onBack={() => navigate('profile')} />
      <div className="p-6 overflow-y-auto pb-32 flex flex-col h-full justify-between">
         <div className="space-y-6">
            <div className="text-center py-4">
               <SmartphoneCharging size={48} className="text-purple-500 mx-auto mb-3" />
               <h3 className="text-lg font-extrabold text-gray-900">Clone Your Phone</h3>
               <p className="text-xs text-gray-500 max-w-[280px] mx-auto mt-1">Transfer all files, apps, and contacts safely from your old phone to your new one in one click.</p>
            </div>

            <div className="grid grid-cols-2 gap-4">
               <div className="border border-purple-100 bg-purple-50/50 p-5 rounded-3xl text-center flex flex-col items-center cursor-pointer hover:border-purple-300 transition-colors">
                  <div className="w-12 h-12 bg-purple-100 text-purple-600 rounded-full flex items-center justify-center mb-3">
                     <FileUp size={22} />
                  </div>
                  <span className="text-sm font-extrabold text-gray-900">Old Phone</span>
                  <span className="text-[10px] font-bold text-purple-600 mt-0.5">SEND DATA</span>
               </div>
               
               <div className="border border-blue-100 bg-blue-50/50 p-5 rounded-3xl text-center flex flex-col items-center cursor-pointer hover:border-blue-300 transition-colors">
                  <div className="w-12 h-12 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mb-3">
                     <Download size={22} />
                  </div>
                  <span className="text-sm font-extrabold text-gray-900">New Phone</span>
                  <span className="text-[10px] font-bold text-blue-600 mt-0.5">RECEIVE DATA</span>
               </div>
            </div>

            <div className="bg-gray-50 border border-gray-100 p-4 rounded-2xl flex items-start gap-3">
               <Info size={18} className="text-purple-500 mt-0.5" />
               <p className="text-[11px] font-bold text-gray-500 leading-relaxed">
                  Both devices will automatically spin up standard, secure, low-latency localized dynamic hotspots to manage the packet transfer safely.
               </p>
            </div>
         </div>

         <button onClick={() => navigate('discovery')} className="w-full py-4 bg-purple-600 text-white font-extrabold rounded-[24px] shadow-lg shadow-purple-600/30 active:scale-95 transition-transform">
            Start Replication
         </button>
      </div>
    </ScreenTransition>
  );
};

const WebShareScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-white">
      <ScreenHeader title="WebShare Portal" onBack={() => navigate('profile')} />
      <div className="p-6 overflow-y-auto pb-32 flex flex-col items-center">
         <Globe size={48} className="text-blue-500 mb-4" />
         <h3 className="text-lg font-extrabold text-gray-900 text-center">Share files to PC or Mobile</h3>
         <p className="text-xs text-gray-500 text-center max-w-[280px] mt-1 mb-6">Connect to the same Wi-Fi and open this direct portal URL on any external browser.</p>

         <div className="bg-gray-900 text-white rounded-3xl p-6 w-full max-w-sm mb-6 flex flex-col items-center relative border border-gray-800 shadow-2xl">
            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">Step 1: Open Server Address</p>
            <div className="bg-gray-800 px-4 py-3 rounded-2xl border border-gray-700 w-full text-center mb-4 font-mono text-sm select-all font-bold tracking-wide flex items-center justify-between">
               <span className="text-blue-400">http://192.168.1.4:8080</span>
               <button className="text-gray-400 hover:text-white"><Copy size={16} /></button>
            </div>
            
            <p className="text-[10px] font-bold text-gray-400 uppercase tracking-widest mb-3">OR Step 2: Scan QR Code</p>
            <div className="bg-white p-3 rounded-2xl shadow-md mb-2">
               <QrCode size={140} className="text-gray-950" />
            </div>
         </div>
      </div>
    </ScreenTransition>
  );
};

const InviteScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-white">
      <ScreenHeader title="Invite Friends" onBack={() => navigate('profile')} />
      <div className="p-6 overflow-y-auto pb-32 flex flex-col items-center">
         <Users size={48} className="text-emerald-500 mb-4" />
         <h3 className="text-lg font-extrabold text-gray-900">Share ShareNova App</h3>
         <p className="text-xs text-gray-500 text-center max-w-[280px] mt-1 mb-6">Introduce your network to dynamic ECDH-encrypted serverless file transfer.</p>

         <div className="bg-emerald-50 border border-emerald-100 rounded-[32px] p-6 flex flex-col items-center w-full mb-6">
            <QrCode size={180} className="text-gray-900 mb-4" />
            <span className="text-xs font-black text-emerald-800 tracking-wide uppercase">Scan to install App</span>
         </div>

         <div className="grid grid-cols-2 gap-4 w-full">
            <button className="p-4 bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-2xl flex flex-col items-center gap-2 font-extrabold text-xs text-gray-900 transition-colors">
               <Wifi size={20} className="text-emerald-600" />
               Share via Hotspot
            </button>
            <button className="p-4 bg-gray-50 hover:bg-gray-100 border border-gray-200 rounded-2xl flex flex-col items-center gap-2 font-extrabold text-xs text-gray-900 transition-colors">
               <Share2 size={20} className="text-emerald-600" />
               Bluetooth Broadcast
            </button>
         </div>
      </div>
    </ScreenTransition>
  );
};

const SettingsScreen = ({ navigate }) => {
  const [switches, setSwitches] = useState({ wifiDirect: true, ecdhRotate: true, notify: false, telemetry: false });

  const toggle = (key) => setSwitches(prev => ({ ...prev, [key]: !prev[key] }));

  return (
    <ScreenTransition className="bg-white">
      <ScreenHeader title="App Settings" onBack={() => navigate('profile')} />
      <div className="p-6 overflow-y-auto pb-32 space-y-6">
         <div>
            <h3 className="text-xs font-extrabold text-gray-400 uppercase tracking-widest mb-3 px-1">Network & Encryption</h3>
            <div className="bg-gray-50 rounded-2xl p-2 border border-gray-100 space-y-1">
               <div className="flex items-center justify-between p-3">
                  <div>
                     <p className="text-sm font-extrabold text-gray-900">Wi-Fi Direct Priority</p>
                  </div>
                  <button onClick={() => toggle('wifiDirect')} className={`w-11 h-6 rounded-full p-0.5 transition-colors ${switches.wifiDirect ? 'bg-blue-600' : 'bg-gray-300'}`}>
                     <div className={`w-5 h-5 rounded-full bg-white transition-transform ${switches.wifiDirect ? 'translate-x-5' : ''}`} />
                  </button>
               </div>
            </div>
         </div>
      </div>
    </ScreenTransition>
  );
};

const CleanScreen = ({ navigate }) => {
  const [cleaning, setCleaning] = useState(false);
  const [cleaned, setCleaned] = useState(false);

  const startClean = () => {
     setCleaning(true);
     setTimeout(() => {
        setCleaning(false);
        setCleaned(true);
     }, 3000);
  };

  return (
    <ScreenTransition className="bg-gray-50">
      <ScreenHeader title="Junk Cleaner" onBack={() => navigate('home')} />
      <div className="p-6 overflow-y-auto pb-32 flex flex-col h-full items-center justify-between">
         <div className="w-full flex flex-col items-center">
            {/* Visual Cleaning Ring */}
            <div className="w-48 h-48 bg-white border border-gray-100 rounded-full shadow-[0_10px_35px_rgba(0,0,0,0.05)] flex items-center justify-center relative mb-6">
               <svg className="absolute w-44 h-44 -rotate-90">
                  <circle cx="88" cy="88" r="80" className="stroke-gray-100 fill-none" strokeWidth="8" />
                  <motion.circle 
                     cx="88" cy="88" r="80" 
                     className="stroke-red-500 fill-none" 
                     strokeWidth="8" 
                     strokeDasharray="502"
                     animate={{ strokeDashoffset: cleaning ? 502 : cleaned ? 502 : 150 }}
                     transition={{ duration: 3, ease: 'easeInOut' }}
                  />
               </svg>
               <div className="flex flex-col items-center z-10 text-center">
                  <Trash2 size={36} className={`${cleaned ? 'text-emerald-500' : 'text-red-500'} mb-1`} />
                  <span className="text-2xl font-black tracking-tighter text-gray-900">{cleaned ? '0.0' : '2.4'} <span className="text-xs font-bold text-gray-500">GB</span></span>
                  <span className="text-[9px] font-bold text-gray-400 uppercase tracking-widest">{cleaning ? 'Sifting cache...' : cleaned ? 'All Cleared' : 'Junk Found'}</span>
               </div>
            </div>
         </div>

         {cleaned ? (
            <button onClick={() => navigate('home')} className="w-full py-4 bg-emerald-600 text-white font-extrabold rounded-[24px] shadow-lg shadow-emerald-600/30 active:scale-95 transition-transform flex items-center justify-center gap-2">
               <CheckCircle2 size={18} /> Finished
            </button>
         ) : (
            <button onClick={startClean} disabled={cleaning} className="w-full py-4 bg-red-600 text-white font-extrabold rounded-[24px] shadow-lg shadow-red-600/30 active:scale-95 transition-transform flex items-center justify-center gap-2 disabled:opacity-50">
               {cleaning ? 'Sifting system caches...' : 'Clean Now'}
            </button>
         )}
      </div>
    </ScreenTransition>
  );
};

const MyFilesScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-white">
      <ScreenHeader title="My Files" subtitle="Received Content Library" onBack={() => navigate('profile')} />
      <div className="p-6 overflow-y-auto pb-32 space-y-4">
         <div className="bg-blue-50 border border-blue-100 rounded-2xl p-4 flex items-center justify-between">
            <div className="flex items-center gap-3">
               <FolderOpen className="text-blue-500" />
               <span className="text-xs font-extrabold text-blue-900">Total Files Synced: 24</span>
            </div>
            <span className="text-xs font-black text-blue-600 bg-white px-2 py-1 rounded shadow-sm">1.8 GB</span>
         </div>

         <div className="space-y-3">
            {RECENT_TRANSFERS.map((file) => (
               <div key={file.id} className="flex items-center justify-between p-3 bg-gray-50 rounded-2xl border border-gray-100 shadow-sm">
                  <div className="flex items-center gap-3">
                     <div className="w-10 h-10 bg-white rounded-xl flex items-center justify-center border border-gray-200">
                        {file.type === 'video' ? <Video size={18} className="text-purple-500" /> : <FileText size={18} className="text-blue-500" />}
                     </div>
                     <div>
                        <p className="text-xs font-extrabold text-gray-900 truncate max-w-[150px]">{file.name}</p>
                        <p className="text-[10px] font-bold text-gray-500 mt-0.5">{file.size}</p>
                     </div>
                  </div>
                  <button className="text-xs font-bold text-blue-600 bg-white border border-gray-200 px-3 py-1.5 rounded-xl hover:bg-gray-100 transition-colors">
                     Open
                  </button>
               </div>
            ))}
         </div>
      </div>
    </ScreenTransition>
  );
};

const ChatListScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-gray-50">
      <ScreenHeader title="P2P Messages" rightIcon={<Search size={22} className="text-gray-600" />} />
      <div className="p-6 overflow-y-auto pb-32 space-y-4">
         <div className="bg-blue-50 border border-blue-100 rounded-2xl p-4 flex items-center gap-4 mb-6">
            <div className="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center text-white"><Radio size={20} /></div>
            <div>
               <h3 className="text-sm font-extrabold text-blue-900">Direct Message Mode</h3>
               <p className="text-[10px] font-bold text-blue-600 mt-0.5">Chat securely over Wi-Fi Direct. No internet required.</p>
            </div>
         </div>

         {MOCK_CONTACTS.map((contact) => (
            <div key={contact.id} onClick={() => navigate('chat_room')} className="flex items-center justify-between p-4 bg-white rounded-2xl border border-gray-100 shadow-sm hover:shadow-md transition-shadow cursor-pointer">
               <div className="flex items-center gap-4 flex-1 overflow-hidden">
                  <div className="relative">
                     <div className={`w-12 h-12 rounded-full flex items-center justify-center font-black text-lg shadow-sm ${contact.color}`}>
                        {contact.initials}
                     </div>
                     <div className={`absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full border-2 border-white ${contact.status.includes('Nearby') ? 'bg-emerald-500' : contact.status.includes('Online') ? 'bg-blue-500' : 'bg-gray-400'}`}></div>
                  </div>
                  <div className="flex-1 overflow-hidden">
                     <div className="flex justify-between items-center mb-1">
                        <p className="text-sm font-extrabold text-gray-900 truncate">{contact.name}</p>
                        <span className="text-[10px] font-bold text-gray-400 flex-shrink-0 ml-2">10:49 AM</span>
                     </div>
                     <p className={`text-xs truncate ${contact.unread > 0 ? 'font-extrabold text-gray-900' : 'font-bold text-gray-500'}`}>
                        {contact.lastMsg}
                     </p>
                  </div>
               </div>
               {contact.unread > 0 && (
                  <div className="w-5 h-5 bg-blue-600 rounded-full flex items-center justify-center ml-3 flex-shrink-0">
                     <span className="text-[10px] font-bold text-white">{contact.unread}</span>
                  </div>
               )}
            </div>
         ))}
      </div>
    </ScreenTransition>
  );
};

const ChatRoomScreen = ({ navigate }) => {
  const [messages, setMessages] = useState(MOCK_CHAT_MESSAGES);
  const [input, setInput] = useState("");
  const endRef = useRef(null);

  useEffect(() => {
     endRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const sendMessage = () => {
     if(!input.trim()) return;
     setMessages([...messages, { id: Date.now(), text: input, sender: 'Me', time: "10:51 AM", isMine: true, type: 'text' }]);
     setInput("");
  };

  return (
    <ScreenTransition className="bg-gray-50 flex flex-col">
      <div className="px-4 py-3 flex items-center justify-between border-b border-gray-100 bg-white/95 backdrop-blur-md z-20 sticky top-0 shadow-sm">
         <div className="flex items-center gap-3">
            <button onClick={() => navigate('chats')} className="p-2 -ml-2 rounded-full hover:bg-gray-100 transition-colors">
               <ArrowLeft size={24} className="text-gray-900" />
            </button>
            <div className="relative">
               <div className="w-10 h-10 rounded-full bg-purple-100 text-purple-600 flex items-center justify-center font-black">SJ</div>
               <div className="absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white bg-emerald-500"></div>
            </div>
            <div className="flex flex-col">
               <h2 className="text-sm font-extrabold text-gray-900 tracking-tight leading-tight">Sarah Jenkins</h2>
               <span className="text-[10px] font-bold text-emerald-600 flex items-center gap-1"><Wifi size={10}/> Nearby (Wi-Fi Direct)</span>
            </div>
         </div>
         <button className="p-2 text-gray-600 hover:bg-gray-100 rounded-full"><MoreVertical size={20}/></button>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-4 pb-4">
         <div className="text-center my-4">
            <span className="text-[10px] font-bold bg-gray-200 text-gray-500 px-3 py-1 rounded-full uppercase tracking-widest">Encrypted P2P Session Started</span>
         </div>

         {messages.map((msg) => (
            <div key={msg.id} className={`flex ${msg.isMine ? 'justify-end' : 'justify-start'}`}>
               <div className={`max-w-[75%] rounded-2xl p-3 shadow-sm ${msg.isMine ? 'bg-blue-600 text-white rounded-tr-sm' : 'bg-white border border-gray-100 text-gray-900 rounded-tl-sm'}`}>
                  
                  {msg.type === 'text' && (
                     <p className="text-[13px] font-bold leading-relaxed">{msg.text}</p>
                  )}

                  {msg.type === 'request' && (
                     <div className="flex flex-col gap-2">
                        <div className="flex items-center gap-2 mb-1">
                           <FileDown size={16} className={msg.isMine ? "text-blue-200" : "text-blue-500"} />
                           <span className={`text-[11px] font-extrabold uppercase ${msg.isMine ? 'text-blue-200' : 'text-blue-600'}`}>Requested File</span>
                        </div>
                        <p className="text-sm font-black truncate">{msg.fileName}</p>
                        <button onClick={() => navigate('files')} className={`mt-2 py-2 w-full rounded-xl text-xs font-extrabold flex justify-center items-center gap-1 transition-transform active:scale-95 ${msg.isMine ? 'bg-white text-blue-600' : 'bg-blue-600 text-white'}`}>
                           <Send size={14}/> Fulfill Request
                        </button>
                     </div>
                  )}

                  {msg.type === 'transfer' && (
                     <div className="flex flex-col gap-2">
                        <div className="flex items-center gap-2 mb-1">
                           <CheckCircle2 size={16} className={msg.isMine ? "text-emerald-300" : "text-emerald-500"} />
                           <span className={`text-[11px] font-extrabold uppercase ${msg.isMine ? 'text-emerald-300' : 'text-emerald-600'}`}>Transfer Complete</span>
                        </div>
                        <div className={`p-2 rounded-xl flex items-center gap-3 ${msg.isMine ? 'bg-blue-700/50' : 'bg-gray-50'}`}>
                           <Video size={20} className={msg.isMine ? "text-white" : "text-purple-500"} />
                           <div className="overflow-hidden">
                              <p className="text-xs font-bold truncate">{msg.fileName}</p>
                              <p className={`text-[10px] font-bold mt-0.5 ${msg.isMine ? 'text-blue-200' : 'text-gray-500'}`}>{msg.size}</p>
                           </div>
                        </div>
                     </div>
                  )}

                  <div className={`text-[9px] font-bold mt-1.5 flex items-center justify-end gap-1 ${msg.isMine ? 'text-blue-200' : 'text-gray-400'}`}>
                     {msg.time} {msg.isMine && <CheckCheck size={12} />}
                  </div>
               </div>
            </div>
         ))}
         <div ref={endRef} />
      </div>

      <div className="px-4 py-2 bg-gray-50 flex gap-2 overflow-x-auto scrollbar-hide border-t border-gray-200 shadow-[0_-5px_15px_rgba(0,0,0,0.02)]">
         <button onClick={() => navigate('files')} className="flex items-center gap-1.5 bg-white border border-gray-200 px-3 py-1.5 rounded-full text-[11px] font-extrabold text-gray-700 hover:bg-gray-100 flex-shrink-0">
            <FileUp size={14} className="text-blue-500" /> Send Files
         </button>
         <button className="flex items-center gap-1.5 bg-white border border-gray-200 px-3 py-1.5 rounded-full text-[11px] font-extrabold text-gray-700 hover:bg-gray-100 flex-shrink-0">
            <FileDown size={14} className="text-purple-500" /> Request File
         </button>
         <button className="flex items-center gap-1.5 bg-white border border-gray-200 px-3 py-1.5 rounded-full text-[11px] font-extrabold text-gray-700 hover:bg-gray-100 flex-shrink-0">
            <Camera size={14} className="text-emerald-500" /> Camera
         </button>
      </div>

      <div className="p-4 bg-white border-t border-gray-200 flex items-center gap-3">
         <button className="p-2 bg-gray-100 rounded-full text-gray-500 hover:bg-gray-200"><Paperclip size={20} /></button>
         <input 
            type="text" 
            placeholder="Type a message..." 
            className="flex-1 bg-gray-100 rounded-full px-4 py-2.5 text-sm font-bold focus:outline-none focus:ring-2 focus:ring-blue-500/50"
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyPress={e => e.key === 'Enter' && sendMessage()}
         />
         {input.trim() ? (
            <button onClick={sendMessage} className="p-2.5 bg-blue-600 rounded-full text-white shadow-md hover:bg-blue-700 transition-colors"><Send size={18} /></button>
         ) : (
            <button className="p-2.5 bg-gray-100 rounded-full text-gray-500 hover:bg-gray-200 transition-colors"><Mic size={18} /></button>
         )}
      </div>
    </ScreenTransition>
  );
};

const QRScannerScreen = ({ navigate }) => {
  return (
    <ScreenTransition className="bg-black text-white relative">
       <div className="absolute top-0 left-0 right-0 p-6 pt-12 flex justify-between items-center z-20 bg-gradient-to-b from-black/80 to-transparent">
          <button onClick={() => navigate('discovery')} className="p-2 bg-gray-900/80 backdrop-blur-md rounded-full text-white hover:bg-gray-800">
             <X size={24} />
          </button>
          <div className="flex gap-4">
             <button className="p-2 bg-gray-900/80 backdrop-blur-md rounded-full text-white"><ImageIcon size={20}/></button>
             <button className="p-2 bg-gray-900/80 backdrop-blur-md rounded-full text-white"><Zap size={20}/></button>
          </div>
       </div>

       <div className="flex-1 flex flex-col items-center justify-center relative overflow-hidden h-full">
          <div className="absolute inset-0 bg-gray-900 opacity-50"></div>
          
          <div className="relative z-10 w-64 h-64 border-2 border-white/20 rounded-3xl overflow-hidden flex items-center justify-center shadow-[0_0_0_4000px_rgba(0,0,0,0.6)]">
             <div className="absolute top-0 left-0 w-8 h-8 border-t-4 border-l-4 border-blue-500 rounded-tl-3xl"></div>
             <div className="absolute top-0 right-0 w-8 h-8 border-t-4 border-r-4 border-blue-500 rounded-tr-3xl"></div>
             <div className="absolute bottom-0 left-0 w-8 h-8 border-b-4 border-l-4 border-blue-500 rounded-bl-3xl"></div>
             <div className="absolute bottom-0 right-0 w-8 h-8 border-b-4 border-r-4 border-blue-500 rounded-br-3xl"></div>
             
             <motion.div 
                className="w-full h-1 bg-blue-500 shadow-[0_0_15px_rgba(59,130,246,0.8)] absolute"
                animate={{ top: ['0%', '100%', '0%'] }}
                transition={{ duration: 3, repeat: Infinity, ease: 'linear' }}
             />
             <ScanLine size={48} className="text-white/20" />
          </div>

          <p className="mt-8 text-sm font-extrabold tracking-wide z-10 text-center px-8">
             Align QR code within the frame to connect automatically.
          </p>
          <button onClick={() => navigate('receive')} className="mt-8 px-6 py-3 bg-blue-600 rounded-full font-extrabold text-sm z-10 shadow-lg shadow-blue-500/30 active:scale-95">
             Simulate Scan
          </button>
       </div>
    </ScreenTransition>
  );
};


export default function ShareNovaApp() {
  const [currentScreen, setCurrentScreen] = useState('splash');
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

  const renderScreen = () => {
    switch (currentScreen) {
      case 'splash': return <SplashScreen onComplete={() => setCurrentScreen('home')} />;
      case 'home': return <HomeScreen navigate={setCurrentScreen} toggleDrawer={() => setIsDrawerOpen(true)} />;
      case 'discover': return <DiscoverScreen navigate={setCurrentScreen} />;
      case 'profile': return <ProfileScreen navigate={setCurrentScreen} />;
      case 'files': return <FileManagerScreen navigate={setCurrentScreen} />;
      case 'discovery': return <DeviceDiscoveryScreen navigate={setCurrentScreen} />;
      case 'qr_scanner': return <QRScannerScreen navigate={setCurrentScreen} />;
      case 'transfer': return <TransferProgressScreen navigate={setCurrentScreen} />;
      case 'receive': return <ReceiveScreen navigate={setCurrentScreen} />;
      case 'analytics': return <AnalyticsScreen navigate={setCurrentScreen} />;
      case 'workspace': return <WorkspaceScreen navigate={setCurrentScreen} />;
      case 'autosync': return <AutoSyncScreen navigate={setCurrentScreen} />;
      case 'history': return <HistoryScreen navigate={setCurrentScreen} />;
      case 'replicate': return <ReplicateScreen navigate={setCurrentScreen} />;
      case 'webshare': return <WebShareScreen navigate={setCurrentScreen} />;
      case 'invite': return <InviteScreen navigate={setCurrentScreen} />;
      case 'settings': return <SettingsScreen navigate={setCurrentScreen} />;
      case 'myfiles': return <MyFilesScreen navigate={setCurrentScreen} />;
      case 'clean': return <CleanScreen navigate={setCurrentScreen} />;
      case 'chats': return <ChatListScreen navigate={setCurrentScreen} />;
      case 'chat_room': return <ChatRoomScreen navigate={setCurrentScreen} />;
      default: return <HomeScreen navigate={setCurrentScreen} toggleDrawer={() => setIsDrawerOpen(true)} />;
    }
  };

  const executeDrawerNav = (route) => {
     setIsDrawerOpen(false);
     setTimeout(() => setCurrentScreen(route), 200);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100 p-4 font-sans selection:bg-blue-200">
      <div className="w-full max-w-[400px] h-[850px] bg-black rounded-[50px] p-2 relative shadow-[0_20px_50px_rgba(0,0,0,0.2)]">
        {/* Hardware Notch */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-40 h-7 bg-black rounded-b-[20px] z-50 flex justify-center items-end pb-1.5">
           <div className="w-16 h-1.5 bg-gray-800 rounded-full"></div>
        </div>

        <div className="w-full h-full bg-white rounded-[40px] overflow-hidden relative border border-gray-800">
          
          <AnimatePresence mode="wait">
             <div key={currentScreen} className="w-full h-full">
                {renderScreen()}
             </div>
          </AnimatePresence>

          {/* Side Navigation Drawer Overlay */}
          <AnimatePresence>
             {isDrawerOpen && (
                <>
                   <motion.div 
                      initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                      onClick={() => setIsDrawerOpen(false)}
                      className="absolute inset-0 bg-black/60 backdrop-blur-sm z-50"
                   />
                   <motion.div 
                      initial={{ x: "-100%" }} animate={{ x: 0 }} exit={{ x: "-100%" }}
                      transition={{ type: "spring", damping: 25, stiffness: 200 }}
                      className="absolute top-0 left-0 bottom-0 w-3/4 bg-white z-50 flex flex-col shadow-2xl overflow-y-auto"
                   >
                      <div className="bg-blue-600 p-6 pt-12 text-white relative overflow-hidden">
                         <div className="absolute -bottom-10 -right-10 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
                         <div className="w-16 h-16 bg-white/20 rounded-full flex items-center justify-center p-1 mb-4 backdrop-blur-sm">
                            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix" className="w-full h-full bg-white rounded-full object-cover" />
                         </div>
                         <h3 className="text-lg font-black tracking-tight">Alex Walker</h3>
                         <p className="text-xs font-bold text-blue-200 mt-1 flex items-center gap-1"><Smartphone size={12}/> Galaxy S24 Ultra</p>
                      </div>

                      <div className="flex-1 py-4 flex flex-col">
                         {[
                            { icon: Monitor, label: 'Connect PC', route: 'webshare' },
                            { icon: Globe, label: 'WebShare', route: 'webshare' },
                            { icon: SmartphoneCharging, label: 'Phone Replicate', route: 'replicate' },
                            { icon: FolderOpen, label: 'My Cloud / Files', route: 'myfiles' },
                            { icon: Grid, label: 'Featured Apps', route: 'discover' },
                         ].map((item, idx) => (
                            <button key={idx} onClick={() => executeDrawerNav(item.route)} className="flex items-center gap-4 px-6 py-4 hover:bg-gray-50 transition-colors w-full text-left text-gray-800 group">
                               <item.icon size={20} className="text-gray-400 group-hover:text-blue-600 transition-colors" />
                               <span className="text-sm font-extrabold group-hover:text-blue-600 transition-colors">{item.label}</span>
                            </button>
                         ))}
                         
                         <div className="h-px bg-gray-100 my-2 mx-6"></div>

                         {[
                            { icon: Settings, label: 'Settings', route: 'settings' },
                            { icon: Info, label: 'About', route: 'home' },
                         ].map((item, idx) => (
                            <button key={idx} onClick={() => executeDrawerNav(item.route)} className="flex items-center gap-4 px-6 py-4 hover:bg-gray-50 transition-colors w-full text-left text-gray-800 group">
                               <item.icon size={20} className="text-gray-400 group-hover:text-gray-900" />
                               <span className="text-sm font-extrabold">{item.label}</span>
                            </button>
                         ))}
                      </div>
                   </motion.div>
                </>
             )}
          </AnimatePresence>

          {/* Global Navigation Bar - Integrated with Chats Tab */}
          {!['splash', 'transfer', 'files', 'discovery', 'receive', 'chat_room', 'qr_scanner'].includes(currentScreen) && (
             <div className="absolute bottom-0 left-0 right-0 bg-white/95 backdrop-blur-xl border-t border-gray-100 px-4 py-4 flex justify-between items-center z-40 pb-8 shadow-[0_-10px_30px_rgba(0,0,0,0.05)]">
                {[
                  { id: 'home', icon: Send, label: 'Share' },
                  { id: 'chats', icon: MessageSquare, label: 'Messages' },
                  { id: 'discover', icon: Compass, label: 'Discover' },
                  { id: 'workspace', icon: Users, label: 'Spaces' },
                  { id: 'profile', icon: User, label: 'Me' }
                ].map(nav => (
                  <button key={nav.id} onClick={() => setCurrentScreen(nav.id)} className="flex flex-col items-center space-y-1 w-[20%] group">
                    <div className={`p-2 rounded-xl transition-all duration-300 ${currentScreen === nav.id ? 'bg-blue-50 text-blue-600 scale-110' : 'text-gray-400 group-hover:text-gray-600'}`}>
                      <nav.icon size={22} fill={currentScreen === nav.id ? "currentColor" : "none"} strokeWidth={currentScreen === nav.id ? 2 : 2} />
                    </div>
                    <span className={`text-[9px] font-bold transition-colors ${currentScreen === nav.id ? 'text-blue-600' : 'text-gray-400'}`}>{nav.label}</span>
                  </button>
                ))}
             </div>
          )}
          
          {/* OS Home Indicator */}
          <div className="absolute bottom-2 left-1/2 -translate-x-1/2 w-32 h-1.5 bg-gray-300 rounded-full z-50"></div>
        </div>
      </div>
    </div>
  );
}