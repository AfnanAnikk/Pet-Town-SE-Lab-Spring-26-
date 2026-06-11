import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import { LayoutDashboard, ShieldAlert, ShoppingBag, TrendingUp, Users, Scissors, Heart, Calendar, MessageSquare, Settings, Search, Bell, Activity, FileText, CheckCircle2, XCircle, X, Download } from 'lucide-react';
import './index.css';
import logo from "./assets/logo.png";

const API_BASE = import.meta.env.VITE_API_URL || 'https://pet-town-backend.onrender.com/api/admin';

function Sidebar() {
  const location = useLocation();

  const menuItems = [
    { name: 'Dashboard', path: '/', icon: <LayoutDashboard size={20} /> },
    { name: 'Content & Feed', path: '/content', icon: <ShieldAlert size={20} /> },
    { name: 'Marketplace', path: '/marketplace', icon: <ShoppingBag size={20} /> },
    { name: 'Finance', path: '/finance', icon: <TrendingUp size={20} /> },
    { name: 'Vet Services', path: '/vets', icon: <Users size={20} /> },
    { name: 'Pet Salon', path: '/salons', icon: <Scissors size={20} /> },
    { name: 'Adoption', path: '/adoption', icon: <Heart size={20} /> },
    { name: 'Events', path: '/events', icon: <Calendar size={20} /> },
    { name: 'Messaging', path: '/messages', icon: <MessageSquare size={20} /> },
  ];

  return (
    <div className="sidebar">
      <div className="sidebar-header">
        <div style={{ width: 36, height: 36, borderRadius: '50%', overflow: 'hidden' }}>
          <img src={logo} alt="PetTown" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
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

// 3. Pet Salon
function PetSalons() {
  const [salons, setSalons] = useState([]);
  const [selectedSalon, setSelectedSalon] = useState(null);

  useEffect(() => {
    fetch(`${API_BASE}/salons/verifications`)
      .then(r => r.json())
      .then(d => {
        const pending = (d.verifications || []).filter(s => s.status === 'pending');
        setSalons(pending);
      });
  }, []);

  const handleApprove = (id) => {
    fetch(`${API_BASE}/salons/verifications/${id}/approve`, { method: 'POST' }).then(() => {
      setSalons(salons.filter(s => s.id !== id));
      setSelectedSalon(null);
    });
  };

  const handleDeny = (id) => {
    fetch(`${API_BASE}/salons/verifications/${id}/deny`, { method: 'POST' }).then(() => {
      setSalons(salons.filter(s => s.id !== id));
      setSelectedSalon(null);
    });
  };

  return (
    <div className="page">
      <h1>Pet Salon</h1>
      <p>Manage grooming partners, reviews, and booking quality.</p>

      {salons.length > 0 && (
        <div className="card" style={{ marginTop: '24px', marginBottom: '24px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '16px' }}>Pending Verifications</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px' }}>
            {salons.map((s, idx) => (
              <div key={idx} style={{ border: '1px solid #E2E8F0', padding: '16px', borderRadius: '12px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                  <div style={{ width: 48, height: 48, background: '#EC4899', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Scissors size={24} color="white" />
                  </div>
                  <span style={{ fontSize: '10px', fontWeight: 'bold', padding: '4px 8px', borderRadius: '4px', background: '#FEF3C7', color: '#F59E0B' }}>
                    PENDING
                  </span>
                </div>
                <h3 style={{ fontSize: '16px', fontWeight: 'bold', color: '#0F172A', marginBottom: '4px' }}>{s.salon_name}</h3>
                <p style={{ fontSize: '13px', color: '#64748B', marginBottom: '16px' }}>{s.location || s.email}</p>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <button style={{ flex: 1, padding: '8px', background: '#F1F5F9', border: 'none', borderRadius: '6px', color: '#475569', fontWeight: 'bold', cursor: 'pointer' }} onClick={() => setSelectedSalon(s)}>Review Documents</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {selectedSalon && (
        <div className="modal-overlay" style={{ backdropFilter: 'blur(6px)', background: 'rgba(15, 23, 42, 0.45)' }}>
          <div
            className="modal-content"
            style={{
              zIndex: 101,
              width: '92%',
              maxWidth: '900px',
              maxHeight: '88vh',
              overflow: 'hidden',
              borderRadius: '24px',
              padding: 0,
              background: '#FFFFFF',
              boxShadow: '0 24px 80px rgba(15, 23, 42, 0.25)',
            }}
          >
            <div style={{ padding: '24px 28px', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12, fontWeight: 800, color: '#EC4899', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
                  Salon Verification
                </div>
                <h2 style={{ fontSize: 24, fontWeight: 800, color: '#0F172A', margin: 0 }}>
                  {selectedSalon.salon_name}
                </h2>
                <p style={{ margin: '6px 0 0', color: '#64748B', fontSize: 14 }}>
                  Review identity, tax, and business documents.
                </p>
              </div>

              <button
                onClick={() => setSelectedSalon(null)}
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  border: '1px solid #E2E8F0',
                  background: '#F8FAFC',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <X size={20} color="#64748B" />
              </button>
            </div>

            <div style={{ padding: '24px 28px', overflowY: 'auto', maxHeight: 'calc(88vh - 176px)' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 24 }}>
                <div style={{ padding: 16, borderRadius: 16, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                  <div style={{ fontSize: 12, color: '#64748B', fontWeight: 700, marginBottom: 6 }}>Owner Name</div>
                  <div style={{ fontSize: 16, color: '#0F172A', fontWeight: 800 }}>{selectedSalon.owner_name || 'Not provided'}</div>
                </div>

                <div style={{ padding: 16, borderRadius: 16, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                  <div style={{ fontSize: 12, color: '#64748B', fontWeight: 700, marginBottom: 6 }}>Application Status</div>
                  <span style={{ display: 'inline-flex', padding: '6px 10px', borderRadius: 999, background: '#FEF3C7', color: '#92400E', fontSize: 12, fontWeight: 800 }}>
                    {selectedSalon.status?.toUpperCase() || 'PENDING'}
                  </span>
                </div>
              </div>

              <h3 style={{ fontSize: 16, fontWeight: 800, color: '#0F172A', marginBottom: 14 }}>
                Submitted Documents
              </h3>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 18 }}>
                <DocumentPreview title="NID Front" url={selectedSalon.nid_front_url} />
                <DocumentPreview title="NID Back" url={selectedSalon.nid_back_url} />
                <DocumentPreview title="TIN Certificate" url={selectedSalon.tin_url} />
                <DocumentPreview title="Trade License" url={selectedSalon.trade_url} />
                <DocumentPreview title="Other Document" url={selectedSalon.other_url} />
              </div>
            </div>

            <div style={{ padding: '18px 28px', borderTop: '1px solid #E2E8F0', display: 'flex', justifyContent: 'flex-end', gap: 12, background: '#F8FAFC' }}>
              <button
                onClick={() => handleDeny(selectedSalon.id)}
                style={{
                  padding: '12px 18px',
                  background: '#FFFFFF',
                  border: '1px solid #FCA5A5',
                  borderRadius: 12,
                  color: '#DC2626',
                  fontWeight: 800,
                  cursor: 'pointer',
                }}
              >
                Deny
              </button>

              <button
                onClick={() => handleApprove(selectedSalon.id)}
                style={{
                  padding: '12px 20px',
                  background: '#10B981',
                  border: 'none',
                  borderRadius: 12,
                  color: 'white',
                  fontWeight: 800,
                  cursor: 'pointer',
                  boxShadow: '0 8px 20px rgba(16, 185, 129, 0.25)',
                }}
              >
                Approve Salon
              </button>
            </div>
          </div>
        </div>
      )}
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
    fetch(`${API_BASE}/stores/verifications`)
      .then(r => r.json())
      .then(d => {
        const pending = (d.verifications || []).filter(v => v.status === 'pending');
        setStores(pending);
      });
  }, []);

  const handleApprove = (id) => {
    fetch(`${API_BASE}/stores/verifications/${id}/approve`, { method: 'POST' }).then(() => {
      setStores(stores.filter(s => s.id !== id));
      setSelectedStore(null);
    });
  }

  const handleDeny = (id) => {
    fetch(`${API_BASE}/stores/verifications/${id}/deny`, { method: 'POST' }).then(() => {
      setStores(stores.filter(s => s.id !== id));
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
        <div className="modal-overlay" style={{ backdropFilter: 'blur(6px)', background: 'rgba(15, 23, 42, 0.45)' }}>
          <div
            className="modal-content"
            style={{
              zIndex: 101,
              width: '92%',
              maxWidth: '760px',
              maxHeight: '86vh',
              overflow: 'hidden',
              borderRadius: '24px',
              padding: 0,
              background: '#FFFFFF',
              boxShadow: '0 24px 80px rgba(15, 23, 42, 0.25)',
            }}
          >
            <div style={{ padding: '24px 28px', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12, fontWeight: 800, color: '#219EBC', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
                  Store Verification
                </div>
                <h2 style={{ fontSize: 24, fontWeight: 800, color: '#0F172A', margin: 0 }}>
                  {selectedStore.store_name}
                </h2>
                <p style={{ margin: '6px 0 0', color: '#64748B', fontSize: 14 }}>
                  Review seller identity and business documents before approval.
                </p>
              </div>

              <button
                onClick={() => setSelectedStore(null)}
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  border: '1px solid #E2E8F0',
                  background: '#F8FAFC',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <X size={20} color="#64748B" />
              </button>
            </div>

            <div style={{ padding: '24px 28px', overflowY: 'auto', height: 'calc(86vh - 174px)' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 24 }}>
                <div style={{ padding: 16, borderRadius: 16, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                  <div style={{ fontSize: 12, color: '#64748B', fontWeight: 700, marginBottom: 6 }}>Owner Name</div>
                  <div style={{ fontSize: 16, color: '#0F172A', fontWeight: 800 }}>{selectedStore.owner_name || 'Not provided'}</div>
                </div>

                <div style={{ padding: 16, borderRadius: 16, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                  <div style={{ fontSize: 12, color: '#64748B', fontWeight: 700, marginBottom: 6 }}>Application Status</div>
                  <span style={{ display: 'inline-flex', padding: '6px 10px', borderRadius: 999, background: '#FEF3C7', color: '#92400E', fontSize: 12, fontWeight: 800 }}>
                    {selectedStore.status?.toUpperCase() || 'PENDING'}
                  </span>
                </div>
              </div>

              <h3 style={{ fontSize: 16, fontWeight: 800, color: '#0F172A', marginBottom: 14 }}>
                Submitted Documents
              </h3>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 18 }}>
                <DocumentPreview title="NID / Identity Document" url={selectedStore.nid_number} />
                <DocumentPreview title="Trade License" url={selectedStore.trade_license} />
              </div>
            </div>

            <div style={{ padding: '18px 28px', borderTop: '1px solid #E2E8F0', display: 'flex', justifyContent: 'flex-end', gap: 12, background: '#F8FAFC', flexShrink: 0,}}>
              <button
                onClick={() => handleDeny(selectedStore.id)}
                style={{
                  padding: '12px 18px',
                  background: '#FFFFFF',
                  border: '1px solid #FCA5A5',
                  borderRadius: 12,
                  color: '#DC2626',
                  fontWeight: 800,
                  cursor: 'pointer',
                }}
              >
                Deny
              </button>

              <button
                onClick={() => handleApprove(selectedStore.id)}
                style={{
                  padding: '12px 20px',
                  background: '#10B981',
                  border: 'none',
                  borderRadius: 12,
                  color: 'white',
                  fontWeight: 800,
                  cursor: 'pointer',
                  boxShadow: '0 8px 20px rgba(16, 185, 129, 0.25)',
                }}
              >
                Approve Store
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// 5. Content Safety
function ContentSafety() {
  const [alerts, setAlerts] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchAlerts = () => {
    fetch(`${API_BASE}/moderation/alerts`)
      .then(r => r.json())
      .then(d => {
        if (d.success) setAlerts(d.alerts || []);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchAlerts();
  }, []);

  const handleAction = (id, action) => {
    fetch(`${API_BASE}/moderation/alerts/${id}/${action}`, { method: 'POST' })
      .then(r => r.json())
      .then(d => {
        if (d.success) {
          if (action === 'dismiss') {
            setAlerts(prev => prev.filter(a => (a.alert_id || a.id) !== id));
          }

          if (action === 'delete-post') {
            setAlerts(prev =>
              prev.map(a =>
                (a.alert_id || a.id) === id
                  ? { ...a, post_deleted: true }
                  : a
              )
            );
          }

          if (action === 'warn-user') {
            setAlerts(prev =>
              prev.map(a =>
                (a.alert_id || a.id) === id
                  ? { ...a, user_warned: true, warning_count: Number(a.warning_count || 0) + 1 }
                  : a
              )
            );
          }

          if (action === 'ban-user') {
            setAlerts(prev =>
              prev.map(a =>
                (a.alert_id || a.id) === id
                  ? { ...a, is_banned: true }
                  : a
              )
            );
          }
        }
        else alert(d.message || 'Action failed');
      })
      .catch(err => {
        console.error(err);
        alert('Action failed');
      });
  };

  return (
    <div className="page">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 16 }}>
        <div>
          <h1>Content Safety</h1>
          <p>Review AI-flagged posts and take moderation action.</p>
        </div>

        <div style={{ padding: '10px 14px', borderRadius: 999, background: alerts.length ? '#FEF3C7' : '#DCFCE7', color: alerts.length ? '#92400E' : '#166534', fontSize: 13, fontWeight: 900 }}>
          {alerts.length} Pending
        </div>
      </div>

      <div style={{ marginTop: 24 }}>
        {loading ? (
          <div className="card" style={{ padding: 28 }}>
            <p style={{ color: '#64748B', margin: 0 }}>Loading alerts...</p>
          </div>
        ) : alerts.length === 0 ? (
          <div style={{ padding: 42, borderRadius: 24, background: '#F8FAFC', border: '1px solid #E2E8F0', textAlign: 'center' }}>
            <CheckCircle2 size={42} color="#10B981" />
            <h2 style={{ fontSize: 22, fontWeight: 900, color: '#0F172A', margin: '14px 0 6px' }}>All clear</h2>
            <p style={{ color: '#64748B', margin: 0 }}>No pending moderation alerts right now.</p>
          </div>
        ) : (
          <div style={{ display: 'grid', gap: 22 }}>
            {alerts.map(alert => {
              const alertId = alert.alert_id || alert.id;
              const postImage = alert.image_path || alert.image_url;
              const userName = alert.display_name || alert.username || alert.author_name || alert.email || 'Unknown User';
              const confidence = Math.round(Number(alert.confidence || 0) * 100);

              return (
                <div key={alertId} style={{ display: 'grid', gridTemplateColumns: '300px 1fr', gap: 24, padding: 18, borderRadius: 26, background: '#FFFFFF', border: '1px solid #CBD5E1', boxShadow: '0 16px 40px rgba(15, 23, 42, 0.08)' }}>
                  <a href={postImage} target="_blank" rel="noreferrer" style={{ display: 'block', borderRadius: 20, overflow: 'hidden', background: '#E2E8F0' }}>
                    <img src={postImage} alt="Flagged post" style={{ width: '100%', height: 320, objectFit: 'cover', display: 'block' }} />
                  </a>

                  <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16, marginBottom: 18 }}>
                      <div style={{ display: 'flex', gap: 12, alignItems: 'center', minWidth: 0 }}>
                        <img src={alert.profile_picture_url || 'https://via.placeholder.com/48'} alt={userName} style={{ width: 52, height: 52, borderRadius: '50%', objectFit: 'cover', background: '#E2E8F0', border: '2px solid #FFFFFF', boxShadow: '0 6px 16px rgba(15,23,42,0.16)' }} />

                        <div style={{ minWidth: 0 }}>
                          <h3 style={{ fontSize: 18, fontWeight: 900, color: '#0F172A', margin: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{userName}</h3>
                          <p style={{ fontSize: 13, color: '#64748B', margin: '3px 0 0' }}>{alert.email || 'No email'}</p>
                        </div>
                      </div>

                      <span style={{ height: 'fit-content', background: '#FEE2E2', color: '#991B1B', padding: '8px 12px', borderRadius: 999, fontSize: 12, fontWeight: 900, border: '1px solid #FCA5A5' }}>
                        {confidence}% confidence
                      </span>
                    </div>

                    <div style={{ padding: 18, borderRadius: 20, background: '#F8FAFC', border: '1px solid #E2E8F0', marginBottom: 16 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                        <ShieldAlert size={18} color="#DC2626" />
                        <span style={{ fontSize: 12, color: '#DC2626', fontWeight: 900, textTransform: 'uppercase', letterSpacing: 0.8 }}>
                          {alert.reason || 'Low pet confidence'}
                        </span>
                      </div>

                      <h2 style={{ fontSize: 24, fontWeight: 900, color: '#0F172A', margin: '0 0 8px' }}>
                        {alert.title || 'Untitled post'}
                      </h2>

                      <p style={{ color: '#475569', fontSize: 14, lineHeight: 1.6, margin: 0 }}>
                        {alert.description || 'No description'}
                      </p>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(6, 1fr)', gap: 10, marginBottom: 18 }}>
                      {[
                        ['Likes', alert.likes_count ?? 0],
                        ['Comments', alert.comments_count ?? 0],
                        ['Warnings', alert.warning_count ?? 0],
                        ['Banned', alert.is_banned ? 'Yes' : 'No'],
                        ['Pet', alert.is_pet ? 'Yes' : 'No'],
                        ['Post', `#${alert.post_id}`],
                      ].map(([label, value]) => (
                        <div key={label} style={{ background: '#FFFFFF', padding: '10px 12px', borderRadius: 14, border: '1px solid #E2E8F0' }}>
                          <div style={{ fontSize: 11, color: '#64748B', fontWeight: 800, marginBottom: 4 }}>{label}</div>
                          <div style={{ fontSize: 14, color: '#0F172A', fontWeight: 900 }}>{value}</div>
                        </div>
                      ))}
                    </div>

                    <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginTop: 'auto' }}>
                      <button onClick={() => handleAction(alertId, 'delete-post')} disabled={alert.post_deleted} style={{ padding: '12px 16px', background: '#DC2626', color: 'white', border: 'none', borderRadius: 14, fontWeight: 900, cursor: 'pointer', boxShadow: '0 8px 20px rgba(220, 38, 38, 0.24)' }}>
                        {alert.post_deleted ? 'Post Deleted' : 'Delete Post'}
                      </button>

                      <button onClick={() => handleAction(alertId, 'warn-user')} disabled={alert.user_warned} style={{ padding: '12px 16px', background: '#F97316', color: 'white', border: 'none', borderRadius: 14, fontWeight: 900, cursor: 'pointer', boxShadow: '0 8px 20px rgba(249, 115, 22, 0.24)' }}>
                        {alert.user_warned ? 'User Warned' : 'Warn User'}
                      </button>

                      <button onClick={() => handleAction(alertId, 'ban-user')} disabled={alert.is_banned} style={{ padding: '12px 16px', background: '#0F172A', color: 'white', border: 'none', borderRadius: 14, fontWeight: 900, cursor: 'pointer', boxShadow: '0 8px 20px rgba(15, 23, 42, 0.22)' }}>
                        {alert.user_warned ? 'User Banned' : 'Ban User'}
                      </button>

                      <button onClick={() => handleAction(alertId, 'dismiss')} style={{ padding: '12px 16px', background: '#FFFFFF', color: '#334155', border: '1px solid #CBD5E1', borderRadius: 14, fontWeight: 900, cursor: 'pointer' }}>
                        Dismiss
                      </button>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
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
  const [appointments, setAppointments] = useState([]);
  const [selectedVet, setSelectedVet] = useState(null);

  useEffect(() => {
    fetch(`${API_BASE}/vets/verifications`)
      .then(r => r.json())
      .then(d => {
        // Only show pending verifications
        const pending = (d.verifications || []).filter(v => v.status === 'pending');
        setVets(pending);
      });
      
    fetch(`${API_BASE}/vets/appointments`)
      .then(r => r.json())
      .then(d => setAppointments(d.appointments || []));
  }, []);

  const handleApprove = (id) => {
    fetch(`${API_BASE}/vets/verifications/${id}/approve`, { method: 'POST' }).then(() => {
      setVets(vets.filter(v => v.id !== id));
      setSelectedVet(null);
    });
  }

  const handleDeny = (id) => {
    fetch(`${API_BASE}/vets/verifications/${id}/deny`, { method: 'POST' }).then(() => {
      setVets(vets.filter(v => v.id !== id));
      setSelectedVet(null);
    });
  }

  return (
    <div className="page">
      <h1>Vet Services</h1>
      <p>Manage verified veterinary professionals and consultation quality.</p>

      {vets.length > 0 && (
        <div className="card" style={{ marginTop: '24px', marginBottom: '24px' }}>
          <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '16px' }}>Pending Verifications</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px' }}>
            {vets.map((v, idx) => (
              <div key={idx} style={{ border: '1px solid #E2E8F0', padding: '16px', borderRadius: '12px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '16px' }}>
                  <div style={{ width: 48, height: 48, background: '#14B8A6', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <Users size={24} color="white" />
                  </div>
                  <span style={{ fontSize: '10px', fontWeight: 'bold', padding: '4px 8px', borderRadius: '4px', background: '#FEF3C7', color: '#F59E0B' }}>
                    PENDING
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
        </div>
      )}

      <div className="card">
        <h3 style={{ fontSize: '16px', fontWeight: 'bold', marginBottom: '24px', color: '#0F172A' }}>Appointments Revenue</h3>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Booking ID</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Doctor</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Patient</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Consultation Fee</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>App Commission (10%)</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Doctor Earns (90%)</th>
              <th style={{ padding: '16px 0', color: '#64748B', fontWeight: 600, borderBottom: '1px solid #E2E8F0' }}>Status</th>
            </tr>
          </thead>
          <tbody>
            {appointments.map((a, i) => (
              <tr key={i}>
                <td style={{ padding: '16px 0', fontWeight: 'bold', color: '#0F172A', borderBottom: '1px solid #F1F5F9' }}>#{a.booking_id}</td>
                <td style={{ padding: '16px 0', color: '#475569', borderBottom: '1px solid #F1F5F9' }}>{a.vet_name}</td>
                <td style={{ padding: '16px 0', color: '#475569', borderBottom: '1px solid #F1F5F9' }}>{a.patient_name}</td>
                <td style={{ padding: '16px 0', fontWeight: 'bold', color: '#0F172A', borderBottom: '1px solid #F1F5F9' }}>${Number(a.consultation_fee).toFixed(2)}</td>
                <td style={{ padding: '16px 0', fontWeight: 'bold', color: '#10B981', borderBottom: '1px solid #F1F5F9' }}>${Number(a.platform_share).toFixed(2)}</td>
                <td style={{ padding: '16px 0', fontWeight: 'bold', color: '#0F172A', borderBottom: '1px solid #F1F5F9' }}>${Number(a.doctor_share).toFixed(2)}</td>
                <td style={{ padding: '16px 0', color: '#475569', borderBottom: '1px solid #F1F5F9' }}>{a.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {selectedVet && (
        <div className="modal-overlay" style={{ backdropFilter: 'blur(6px)', background: 'rgba(15, 23, 42, 0.45)' }}>
          <div
            className="modal-content"
            style={{
              zIndex: 101,
              width: '92%',
              maxWidth: '900px',
              maxHeight: '88vh',
              overflow: 'hidden',
              borderRadius: '24px',
              padding: 0,
              background: '#FFFFFF',
              boxShadow: '0 24px 80px rgba(15, 23, 42, 0.25)',
            }}
          >
            <div style={{ padding: '24px 28px', borderBottom: '1px solid #E2E8F0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ fontSize: 12, fontWeight: 800, color: '#14B8A6', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 6 }}>
                  Vet Verification
                </div>
                <h2 style={{ fontSize: 24, fontWeight: 800, color: '#0F172A', margin: 0 }}>
                  {selectedVet.vet_name}
                </h2>
                <p style={{ margin: '6px 0 0', color: '#64748B', fontSize: 14 }}>
                  Review identity, tax, trade, and professional certification documents.
                </p>
              </div>

              <button
                onClick={() => setSelectedVet(null)}
                style={{
                  width: 40,
                  height: 40,
                  borderRadius: '50%',
                  border: '1px solid #E2E8F0',
                  background: '#F8FAFC',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <X size={20} color="#64748B" />
              </button>
            </div>

            <div style={{ padding: '24px 28px', overflowY: 'auto', maxHeight: 'calc(88vh - 176px)' }}>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 24 }}>
                <div style={{ padding: 16, borderRadius: 16, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                  <div style={{ fontSize: 12, color: '#64748B', fontWeight: 700, marginBottom: 6 }}>Degree</div>
                  <div style={{ fontSize: 16, color: '#0F172A', fontWeight: 800 }}>{selectedVet.degree || 'Not provided'}</div>
                </div>

                <div style={{ padding: 16, borderRadius: 16, background: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                  <div style={{ fontSize: 12, color: '#64748B', fontWeight: 700, marginBottom: 6 }}>Application Status</div>
                  <span style={{ display: 'inline-flex', padding: '6px 10px', borderRadius: 999, background: '#FEF3C7', color: '#92400E', fontSize: 12, fontWeight: 800 }}>
                    {selectedVet.status?.toUpperCase() || 'PENDING'}
                  </span>
                </div>
              </div>

              <h3 style={{ fontSize: 16, fontWeight: 800, color: '#0F172A', marginBottom: 14 }}>
                Submitted Documents
              </h3>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, minmax(0, 1fr))', gap: 18 }}>
                <DocumentPreview title="NID Front" url={selectedVet.nid_front_url} />
                <DocumentPreview title="NID Back" url={selectedVet.nid_back_url} />
                <DocumentPreview title="TIN Certificate" url={selectedVet.tin_url} />
                <DocumentPreview title="Trade License" url={selectedVet.trade_url} />
                <DocumentPreview title="BVC Certificate" url={selectedVet.bvc_url} />
              </div>
            </div>

            <div style={{ padding: '18px 28px', borderTop: '1px solid #E2E8F0', display: 'flex', justifyContent: 'flex-end', gap: 12, background: '#F8FAFC' }}>
              <button
                onClick={() => handleDeny(selectedVet.id)}
                style={{
                  padding: '12px 18px',
                  background: '#FFFFFF',
                  border: '1px solid #FCA5A5',
                  borderRadius: 12,
                  color: '#DC2626',
                  fontWeight: 800,
                  cursor: 'pointer',
                }}
              >
                Deny
              </button>

              <button
                onClick={() => handleApprove(selectedVet.id)}
                style={{
                  padding: '12px 20px',
                  background: '#10B981',
                  border: 'none',
                  borderRadius: 12,
                  color: 'white',
                  fontWeight: 800,
                  cursor: 'pointer',
                  boxShadow: '0 8px 20px rgba(16, 185, 129, 0.25)',
                }}
              >
                Approve Vet
              </button>
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
