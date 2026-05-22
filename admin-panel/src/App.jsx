import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, ShieldAlert, ShoppingBag, TrendingUp, Users, Scissors, Heart, Calendar, MessageSquare, Settings, Search, Bell, Activity, FileText, CheckCircle2, XCircle, X, Download } from 'lucide-react';
import './index.css';

const API_BASE = import.meta.env.VITE_API_URL || 'https://pet-town-backend.onrender.com/api/admin';

function Sidebar() {
  const location = useLocation();

  const menuItems = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={20} /> },
    { name: 'Content & Feed', path: '/content', icon: <ShieldAlert size={20} /> },
    { name: 'Marketplace', path: '/marketplace', icon: <ShoppingBag size={20} /> },
    { name: 'Finance', path: '/finance', icon: <TrendingUp size={20} /> },
    { name: 'Vet Services', path: '/vets', icon: <Users size={20} /> },
    { name: 'Pet Salons', path: '/salons', icon: <Scissors size={20} /> },
    { name: 'Adoption', path: '/adoption', icon: <Heart size={20} /> },
    { name: 'Events', path: '/events', icon: <Calendar size={20} /> },
    { name: 'Messaging', path: '/messages', icon: <MessageSquare size={20} /> },
  ];

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <div style={{ width: 36, height: 36, background: '#1E293B', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ color: 'white', fontSize: 18 }}>🐱</span>
        </div>
        <h2>Pet Town</h2>
      </div>
      <nav className="sidebar-nav">
        {menuItems.map((item) => (
          <Link key={item.name} to={item.path} className={`nav-item ${location.pathname === item.path ? 'active' : ''}`}>
            {item.icon}
            <span>{item.name}</span>
          </Link>
        ))}
      </nav>
      <div className="sidebar-footer">
        <Link to="/settings" className="nav-item">
          <Settings size={20} />
          <span>Settings</span>
        </Link>
      </div>
    </div>
  );
}

function Topbar() {
  return (
    <div className="topbar">
      <div className="search-bar">
        <Search size={18} color="#94A3B8" />
        <input type="text" placeholder="Search users, orders, or reports" />
      </div>
      <div className="topbar-actions">
        <div style={{ position: 'relative', cursor: 'pointer' }}>
          <Bell size={24} color="#64748B" />
          <div style={{ position: 'absolute', top: 2, right: 2, width: 8, height: 8, background: '#EF4444', borderRadius: '50%' }}></div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div className="avatar">A</div>
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontSize: 14, fontWeight: 600, color: '#0F172A' }}>Admin User</span>
            <span style={{ fontSize: 12, color: '#64748B' }}>Super Admin</span>
          </div>
        </div>
      </div>
    </div>
  );
}

// Helper for Document Preview
function DocumentPreview({ title, url }) {
  if (!url) return null;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
      <span style={{ fontSize: '14px', fontWeight: '600', color: '#475569' }}>{title}</span>
      <a href={url} target="_blank" rel="noreferrer" style={{ textDecoration: 'none' }}>
        <div style={{ 
          width: '100%', 
          height: '160px', 
          backgroundColor: '#F8FAFC', 
          borderRadius: '8px', 
          border: '1px solid #E2E8F0',
          overflow: 'hidden',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          cursor: 'zoom-in',
          transition: 'border-color 0.2s',
        }}>
          {url.match(/\.(jpeg|jpg|gif|png|webp)$/i) || url.includes('res.cloudinary.com') ? (
            <img src={url} alt={title} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '8px', color: '#64748B' }}>
              <FileText size={32} />
              <span style={{ fontSize: '12px' }}>View Document</span>
            </div>
          )}
        </div>
      </a>
    </div>
  );
}

// 1. Dashboard
function Dashboard() {
  const [stats, setStats] = useState({ activeUsers: 0, verificationQueue: 0, totalPosts: 0 });

  useEffect(() => {
    fetch(`${API_BASE}/dashboard`)
      .then(res => res.json())
      .then(data => { if (data.success) setStats(data.stats); })
      .catch(console.error);
  }, []);

  return (
    <div className="page">
      <h1>Platform Pulse</h1>
      <p>Real-time overview of community health and operations.</p>
      
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginBottom: '24px' }}>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <ShieldAlert size={24} color="#10B981" />
            <span style={{ color: '#10B981', fontSize: '12px', fontWeight: 'bold' }}>↗ +0.4%</span>
          </div>
          <h2 style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A', marginBottom: '4px' }}>98.2%</h2>
          <span style={{ color: '#64748B', fontSize: '14px' }}>Community trust score</span>
        </div>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <Users size={24} color="#8B5CF6" />
            <span style={{ color: '#10B981', fontSize: '12px', fontWeight: 'bold' }}>Live</span>
          </div>
          <h2 style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A', marginBottom: '4px' }}>{stats.activeUsers}</h2>
          <span style={{ color: '#64748B', fontSize: '14px' }}>Active Users</span>
        </div>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <Activity size={24} color="#EF4444" />
            <span style={{ color: '#EF4444', fontSize: '12px', fontWeight: 'bold' }}>Live</span>
          </div>
          <h2 style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A', marginBottom: '4px' }}>{stats.totalPosts}</h2>
          <span style={{ color: '#64748B', fontSize: '14px' }}>Total Posts</span>
        </div>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <FileText size={24} color="#334155" />
            <span style={{ color: '#219EBC', fontSize: '12px', fontWeight: 'bold' }}>↗ Pending</span>
          </div>
          <h2 style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A', marginBottom: '4px' }}>{stats.verificationQueue}</h2>
          <span style={{ color: '#64748B', fontSize: '14px' }}>Verification Queue</span>
        </div>
      </div>
    </div>
  );
}

// 2. Events (Mocked as no backend table exists yet for events)
function CommunityEvents() {
  const [selectedEvent, setSelectedEvent] = useState(null);

  const events = [
    { date: '14', month: 'JAN', title: 'Golden Retriever Meetup', users: 48, loc: 'Shahabuddin Park, Gulshan, Dhaka', host: 'Dhaka Goldens', status: 'Pending', sColor: '#FDF6B2', tColor: '#92400E', density: 48, risk: 'Low', rating: 4.9, img: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=400&q=80' },
  ];

  return (
    <div className="page" style={{ position: 'relative' }}>
      <h1>Community Events</h1>
      <p>Approve meetups and monitor gathering safety.</p>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 2fr', gap: '24px' }}>
        <div className="card">
          <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '16px' }}>Upcoming Approvals</h3>
          {events.map(e => (
            <div key={e.title} onClick={() => setSelectedEvent(e)} style={{ display: 'flex', alignItems: 'center', padding: '16px', border: '1px solid #E2E8F0', borderRadius: '12px', marginBottom: '16px', cursor: 'pointer', transition: '0.2s', ':hover': { borderColor: '#3B82F6' } }}>
              <div style={{ background: '#EEF2FF', width: '56px', height: '64px', borderRadius: '8px', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', marginRight: '16px' }}>
                <span style={{ color: '#4F46E5', fontSize: '20px', fontWeight: 'bold' }}>{e.date}</span>
                <span style={{ color: '#6366F1', fontSize: '12px', fontWeight: 'bold' }}>{e.month}</span>
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: '15px', fontWeight: 'bold', color: '#0F172A', marginBottom: '4px' }}>{e.title}</div>
                <div style={{ fontSize: '12px', color: '#64748B', display: 'flex', gap: '12px' }}>
                  <span>👥 {e.users}</span>
                  <span>📍 {e.loc}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
      {selectedEvent && (
        <>
          <div className="modal-overlay" style={{ background: 'rgba(0,0,0,0.1)' }} onClick={() => setSelectedEvent(null)}></div>
          <div className="sidebar-overlay">
            <div style={{ padding: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid #E2E8F0' }}>
              <h2 style={{ fontSize: '18px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '12px' }}>
                <X size={20} color="#64748B" style={{ cursor: 'pointer' }} onClick={() => setSelectedEvent(null)} /> Event Inspector
              </h2>
            </div>
            <div style={{ padding: '24px', flex: 1, overflowY: 'auto' }}>
              <button style={{ width: '100%', padding: '12px', background: '#219EBC', color: 'white', border: 'none', borderRadius: '8px', fontWeight: 'bold', cursor: 'pointer' }} onClick={() => setSelectedEvent(null)}>Approve Event</button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

// 3. Pet Salons (Uses Store Verifications for now, similar to vets)
function PetSalons() {
  return (
    <div className="page">
      <h1>Pet Salons</h1>
      <p>Manage grooming partners, reviews, and booking quality.</p>
    </div>
  );
}

// 4. Marketplace Oversight
function MarketplaceOversight() {
  const [orders, setOrders] = useState([]);
  const [stores, setStores] = useState([]);
  const [selectedStore, setSelectedStore] = useState(null);

  useEffect(() => {
    fetch(`${API_BASE}/orders`).then(r => r.json()).then(d => setOrders(d.orders || []));
    fetch(`${API_BASE}/stores/verifications`).then(r => r.json()).then(d => setStores(d.verifications || []));
  }, []);

  const handleApprove = (id) => {
    fetch(`${API_BASE}/stores/verifications/${id}/approve`, { method: 'POST' }).then(() => {
      setStores(stores.map(s => s.id === id ? { ...s, status: 'approved' } : s));
      setSelectedStore(null);
    });
  }

  const handleDeny = (id) => {
    fetch(`${API_BASE}/stores/verifications/${id}/deny`, { method: 'POST' }).then(() => {
      setStores(stores.map(s => s.id === id ? { ...s, status: 'denied' } : s));
      setSelectedStore(null);
    });
  }

  return (
    <div className="page">
      <h1>Marketplace Oversight</h1>
      <p>Monitor merchant sales, resolve disputes, and approve store sellers.</p>

      <div className="card" style={{ marginBottom: 24 }}>
        <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '16px' }}>Store Verifications</h3>
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: '16px' }}>
          {stores.map(s => (
            <div key={s.id} onClick={() => setSelectedStore(s)} style={{ padding: '16px', border: '1px solid #E2E8F0', borderRadius: '8px', cursor: 'pointer' }}>
              <h4>{s.store_name}</h4>
              <p style={{ fontSize: 12, color: '#64748B' }}>Status: {s.status}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="card">
        <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '24px', color: '#0F172A' }}>Recent Orders</h3>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Order ID</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Buyer</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Merchant</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Amount</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((d, i) => (
              <tr key={i}>
                <td style={{ padding: '16px 0', fontWeight: 'bold', color: '#0F172A', borderBottom: '1px solid #F1F5F9' }}>#{d.order_id}</td>
                <td style={{ padding: '16px 0', color: '#475569', borderBottom: '1px solid #F1F5F9' }}>{d.buyer_name}</td>
                <td style={{ padding: '16px 0', color: '#475569', borderBottom: '1px solid #F1F5F9' }}>{d.merchant_name}</td>
                <td style={{ padding: '16px 0', fontWeight: 'bold', color: '#0F172A', borderBottom: '1px solid #F1F5F9' }}>${Number(d.total_price).toFixed(2)}</td>
                <td style={{ padding: '16px 0', color: '#475569', borderBottom: '1px solid #F1F5F9' }}>{d.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedStore && (
        <div className="modal-overlay">
          <div className="modal-overlay" onClick={() => setSelectedStore(null)} style={{ background: 'transparent' }}></div>
          <div className="modal-content" style={{ zIndex: 101, width: '90%', maxWidth: '600px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h2 style={{ fontSize: '24px', fontWeight: 'bold' }}>Verify Store: {selectedStore.store_name}</h2>
              <X size={24} color="#64748B" style={{ cursor: 'pointer' }} onClick={() => setSelectedStore(null)} />
            </div>
            
            <div style={{ padding: '0 0 24px 0' }}>
              <p style={{ fontSize: '16px', marginBottom: '24px' }}><strong>Owner Name:</strong> {selectedStore.owner_name}</p>
              
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
                <DocumentPreview title="NID Front" url={selectedStore.nid_number} />
                <DocumentPreview title="Trade License" url={selectedStore.trade_license} />
              </div>

              <div style={{ display: 'flex', gap: '16px', marginTop: 32, paddingTop: 24, borderTop: '1px solid #E2E8F0' }}>
                <button style={{ flex: 1, padding: '12px 16px', background: '#10B981', border: 'none', borderRadius: '8px', color: 'white', fontWeight: 'bold', cursor: 'pointer' }} onClick={() => handleApprove(selectedStore.id)}>Approve Application</button>
                <button style={{ flex: 1, padding: '12px 16px', background: '#EF4444', border: 'none', borderRadius: '8px', color: 'white', fontWeight: 'bold', cursor: 'pointer' }} onClick={() => handleDeny(selectedStore.id)}>Deny Application</button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// 5. Content Safety (Mocked as no backend table exists for cases)
function ContentSafety() {
  return (
    <div className="page">
      <h1>Content Safety</h1>
      <p>Review flagged content and maintain community guidelines.</p>
    </div>
  );
}

// 6. Finance
function Finance() {
  const [finance, setFinance] = useState({ totalNetRevenue: 0, serviceCommissions: 0, marketplaceFees: 0, adRevenue: 0 });

  useEffect(() => {
    fetch(`${API_BASE}/finance`).then(r => r.json()).then(d => setFinance(d.stats || {}));
  }, []);

  return (
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '24px' }}>
        <div>
          <h1>Platform Revenue</h1>
          <p>Detailed breakdown of income streams: Services, Marketplace, and Ads.</p>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginBottom: '24px' }}>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <span style={{ color: '#10B981', fontWeight: 'bold', fontSize: '18px' }}>$</span>
          </div>
          <h2 style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A', marginBottom: '4px' }}>${finance.totalNetRevenue.toFixed(2)}</h2>
          <span style={{ color: '#64748B', fontSize: '14px' }}>Total Net Revenue</span>
        </div>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <div style={{ width: 24, height: 24, background: '#F1F5F9', borderRadius: '6px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}><ShoppingBag size={14} color="#334155"/></div>
          </div>
          <h2 style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A', marginBottom: '4px' }}>${finance.serviceCommissions.toFixed(2)}</h2>
          <span style={{ color: '#64748B', fontSize: '14px' }}>Vet Commissions (10%)</span>
        </div>
        <div className="card">
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <Activity size={24} color="#EF4444" />
          </div>
          <h2 style={{ fontSize: '32px', fontWeight: 800, color: '#0F172A', marginBottom: '4px' }}>${finance.marketplaceFees.toFixed(2)}</h2>
          <span style={{ color: '#64748B', fontSize: '14px' }}>Marketplace Fees (8%)</span>
        </div>
      </div>
    </div>
  );
}

// 7. Vet Services
function VetServices() {
  const [vets, setVets] = useState([]);
  const [selectedVet, setSelectedVet] = useState(null);

  useEffect(() => {
    fetch(`${API_BASE}/vets/verifications`).then(r => r.json()).then(d => setVets(d.verifications || []));
  }, []);

  const handleApprove = (id) => {
    fetch(`${API_BASE}/vets/verifications/${id}/approve`, { method: 'POST' }).then(() => {
      setVets(vets.map(v => v.id === id ? { ...v, status: 'approved' } : v));
      setSelectedVet(null);
    });
  }

  const handleDeny = (id) => {
    fetch(`${API_BASE}/vets/verifications/${id}/deny`, { method: 'POST' }).then(() => {
      setVets(vets.map(v => v.id === id ? { ...v, status: 'denied' } : v));
      setSelectedVet(null);
    });
  }

  return (
    <div className="page">
      <h1>Vet Services</h1>
      <p>Manage verified veterinary professionals and consultation quality.</p>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginTop: '24px' }}>
        {vets.map((v, idx) => (
          <div key={idx} className="card" style={{ border: '1px solid #E2E8F0' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
              <div style={{ width: 48, height: 48, background: '#14B8A6', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Users size={24} color="white" />
              </div>
              <span style={{ fontSize: '10px', fontWeight: 'bold', padding: '4px 8px', borderRadius: '4px', background: v.status === 'approved' ? '#D1FAE5' : '#FEF3C7', color: v.status === 'approved' ? '#10B981' : '#F59E0B' }}>
                {v.status.toUpperCase()}
              </span>
            </div>
            <h3 style={{ fontSize: '16px', fontWeight: 'bold', color: '#0F172A', marginBottom: '4px' }}>{v.vet_name}</h3>
            <p style={{ fontSize: '13px', color: '#64748B', marginBottom: '16px' }}>{v.degree}</p>
            <div style={{ display: 'flex', gap: '12px' }}>
              <button style={{ flex: 1, padding: '8px', background: '#F1F5F9', border: 'none', borderRadius: '6px', color: '#475569', fontWeight: 'bold', cursor: 'pointer' }} onClick={() => setSelectedVet(v)}>Review Documents</button>
            </div>
          </div>
        ))}
      </div>

      {selectedVet && (
        <div className="modal-overlay">
          <div className="modal-overlay" onClick={() => setSelectedVet(null)} style={{ background: 'transparent' }}></div>
          <div className="modal-content" style={{ zIndex: 101, width: '90%', maxWidth: '800px', maxHeight: '90vh', overflowY: 'auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
              <h2 style={{ fontSize: '24px', fontWeight: 'bold' }}>Verify Vet: {selectedVet.vet_name}</h2>
              <X size={24} color="#64748B" style={{ cursor: 'pointer' }} onClick={() => setSelectedVet(null)} />
            </div>
            
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '20px' }}>
              <DocumentPreview title="NID Front" url={selectedVet.nid_front_url} />
              <DocumentPreview title="NID Back" url={selectedVet.nid_back_url} />
              <DocumentPreview title="TIN Certificate" url={selectedVet.tin_url} />
              <DocumentPreview title="Trade License" url={selectedVet.trade_url} />
              <DocumentPreview title="BVC Certificate" url={selectedVet.bvc_url} />
            </div>
            
            <div style={{ display: 'flex', gap: '16px', marginTop: 32, paddingTop: 24, borderTop: '1px solid #E2E8F0' }}>
              <button style={{ flex: 1, padding: '12px 16px', background: '#10B981', border: 'none', borderRadius: '8px', color: 'white', fontWeight: 'bold', cursor: 'pointer' }} onClick={() => handleApprove(selectedVet.id)}>Approve Application</button>
              <button style={{ flex: 1, padding: '12px 16px', background: '#EF4444', border: 'none', borderRadius: '8px', color: 'white', fontWeight: 'bold', cursor: 'pointer' }} onClick={() => handleDeny(selectedVet.id)}>Deny Application</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// 8. Adoption Center
function AdoptionCenter() {
  const [adoptions, setAdoptions] = useState([]);

  useEffect(() => {
    fetch(`${API_BASE}/adoptions`).then(r => r.json()).then(d => setAdoptions(d.adoptions || []));
  }, []);

  const avail = adoptions.filter(a => a.status === 'available');
  const pending = adoptions.filter(a => a.status === 'pending');
  const adopted = adoptions.filter(a => a.status === 'adopted');

  return (
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <h1>Adoption Center</h1>
          <p>Manage shelter listings and adoption workflows.</p>
        </div>
        <button style={{ background: '#219EBC', color: 'white', padding: '10px 20px', borderRadius: '8px', border: 'none', fontWeight: 'bold', cursor: 'pointer' }}>
          + Add New Listing
        </button>
      </div>

      <div className="search-bar" style={{ marginTop: 24, padding: '12px 16px', width: '100%' }}>
        <Search size={18} color="#94A3B8" />
        <input type="text" placeholder="Search pets or shelters..." style={{ fontSize: 14 }} />
      </div>

      <div className="adoption-board">
        <div className="adoption-column">
          <div className="adoption-col-header">
            <div className="adoption-col-title">
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#14B8A6' }}></div> Available
            </div>
            <div className="adoption-badge">{avail.length}</div>
          </div>
          {avail.map((a, i) => <AdoptionCard key={i} data={a} />)}
        </div>

        <div className="adoption-column">
          <div className="adoption-col-header">
            <div className="adoption-col-title">
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#F59E0B' }}></div> Application Pending
            </div>
            <div className="adoption-badge">{pending.length}</div>
          </div>
          {pending.map((a, i) => <AdoptionCard key={i} data={a} />)}
        </div>

        <div className="adoption-column">
          <div className="adoption-col-header">
            <div className="adoption-col-title">
              <div style={{ width: 8, height: 8, borderRadius: '50%', background: '#6366F1' }}></div> Adopted History
            </div>
            <div className="adoption-badge">{adopted.length}</div>
          </div>
          {adopted.map((a, i) => <AdoptionCard key={i} data={a} />)}
        </div>
      </div>
    </div>
  );
}

function AdoptionCard({ data }) {
  return (
    <div className="adoption-card">
      <img src={data.image_url || 'https://via.placeholder.com/80'} alt={data.name} className="adoption-img" />
      <div className="adoption-details">
        <div className="adoption-name">{data.name}</div>
        <div className="adoption-desc">{data.description}</div>
        <div className="adoption-meta">{data.breed} • {data.age}</div>
        <div className="adoption-meta">{data.species} #{data.id}</div>
      </div>
    </div>
  );
}

export default function App() {
  return (
    <Router>
      <div className="app-container">
        <Sidebar />
        <div className="main-wrapper">
          <Topbar />
          <main className="main-content">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/content" element={<ContentSafety />} />
              <Route path="/marketplace" element={<MarketplaceOversight />} />
              <Route path="/finance" element={<Finance />} />
              <Route path="/vets" element={<VetServices />} />
              <Route path="/salons" element={<PetSalons />} />
              <Route path="/adoption" element={<AdoptionCenter />} />
              <Route path="/events" element={<CommunityEvents />} />
              <Route path="/messages" element={<div className="page"><h1>Messaging</h1></div>} />
            </Routes>
          </main>
        </div>
      </div>
    </Router>
  );
}
