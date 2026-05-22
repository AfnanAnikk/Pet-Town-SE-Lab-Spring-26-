const db = require('../config/db');

// --- FINANCE ---
exports.getFinanceStats = async (req, res) => {
  try {
    // Vet Commission (10% of completed bookings)
    // For demo purposes, we will just sum all bookings since we don't have a 'completed' status universally enforced yet, or we check status='completed'
    const [bookings] = await db.execute(`
      SELECT SUM(v.price) as total_vet_revenue 
      FROM bookings b 
      JOIN vets v ON b.vet_id = v.id 
      WHERE b.status != 'cancelled'
    `);
    
    // Marketplace Commission (8% of all completed orders)
    const [orders] = await db.execute(`
      SELECT SUM(total_price) as total_marketplace_gmv 
      FROM orders 
      WHERE status != 'cancelled'
    `);

    const vetRevenue = Number(bookings[0].total_vet_revenue) || 0;
    const vetCommission = vetRevenue * 0.10;

    const marketplaceGMV = Number(orders[0].total_marketplace_gmv) || 0;
    const marketplaceCommission = marketplaceGMV * 0.08;

    const totalNetRevenue = vetCommission + marketplaceCommission;
    
    res.json({
      success: true,
      stats: {
        totalNetRevenue,
        adRevenue: 45200, // mock ad revenue
        serviceCommissions: vetCommission,
        marketplaceFees: marketplaceCommission,
        marketplaceGMV
      }
    });
  } catch (error) {
    console.error('Error fetching finance stats:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// --- VET VERIFICATIONS ---
exports.getVetVerifications = async (req, res) => {
  try {
    const [verifications] = await db.execute(`
      SELECT vv.*, v.name as vet_name, v.degree, v.location, u.email
      FROM vet_verifications vv
      JOIN vets v ON vv.vet_id = v.id
      JOIN users u ON v.user_id = u.id
      ORDER BY vv.created_at DESC
    `);
    res.json({ success: true, verifications });
  } catch (error) {
    console.error('Error fetching vet verifications:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.approveVet = async (req, res) => {
  const { id } = req.params;
  try {
    // Get the vet_id from the verification
    const [verifs] = await db.execute('SELECT vet_id FROM vet_verifications WHERE id = ?', [id]);
    if (verifs.length === 0) return res.status(404).json({ success: false, message: 'Verification not found' });
    
    const vetId = verifs[0].vet_id;

    await db.execute('UPDATE vet_verifications SET status = ? WHERE id = ?', ['approved', id]);
    await db.execute('UPDATE vets SET is_verified = ? WHERE id = ?', [true, vetId]);
    
    res.json({ success: true, message: 'Vet approved' });
  } catch (error) {
    console.error('Error approving vet:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.denyVet = async (req, res) => {
  const { id } = req.params;
  try {
    const [verifs] = await db.execute('SELECT vet_id FROM vet_verifications WHERE id = ?', [id]);
    if (verifs.length === 0) return res.status(404).json({ success: false, message: 'Verification not found' });
    const vetId = verifs[0].vet_id;

    await db.execute('UPDATE vet_verifications SET status = ? WHERE id = ?', ['denied', id]);
    await db.execute('UPDATE vets SET is_verified = ? WHERE id = ?', [false, vetId]);

    res.json({ success: true, message: 'Vet denied' });
  } catch (error) {
    console.error('Error denying vet:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getVetAppointments = async (req, res) => {
  try {
    const [appointments] = await db.execute(`
      SELECT 
        b.id as booking_id, 
        v.name as vet_name, 
        u.username as patient_name, 
        v.price as consultation_fee, 
        b.status 
      FROM bookings b
      JOIN vets v ON b.vet_id = v.id
      JOIN users u ON b.user_id = u.id
      ORDER BY b.id DESC
      LIMIT 50
    `);
    
    // Calculate shares
    const processed = appointments.map(a => {
      const fee = Number(a.consultation_fee) || 0;
      const platformShare = fee * 0.10;
      const doctorShare = fee * 0.90;
      return {
        ...a,
        platform_share: platformShare,
        doctor_share: doctorShare
      };
    });
    
    res.json({ success: true, appointments: processed });
  } catch (error) {
    console.error('Error fetching appointments:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// --- STORE VERIFICATIONS ---
exports.getStoreVerifications = async (req, res) => {
  try {
    const [verifications] = await db.execute(`
      SELECT sv.*, s.name as store_name, s.contact_info, u.email
      FROM store_verifications sv
      JOIN stores s ON sv.store_id = s.id
      JOIN users u ON s.user_id = u.id
      ORDER BY sv.created_at DESC
    `);
    res.json({ success: true, verifications });
  } catch (error) {
    console.error('Error fetching store verifications:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.approveStore = async (req, res) => {
  const { id } = req.params;
  try {
    const [verifs] = await db.execute('SELECT store_id FROM store_verifications WHERE id = ?', [id]);
    if (verifs.length === 0) return res.status(404).json({ success: false, message: 'Verification not found' });
    
    const storeId = verifs[0].store_id;

    await db.execute('UPDATE store_verifications SET status = ? WHERE id = ?', ['approved', id]);
    await db.execute('UPDATE stores SET is_verified = ? WHERE id = ?', [true, storeId]);
    
    res.json({ success: true, message: 'Store approved' });
  } catch (error) {
    console.error('Error approving store:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.denyStore = async (req, res) => {
  const { id } = req.params;
  try {
    const [verifs] = await db.execute('SELECT store_id FROM store_verifications WHERE id = ?', [id]);
    if (verifs.length === 0) return res.status(404).json({ success: false, message: 'Verification not found' });
    const storeId = verifs[0].store_id;

    await db.execute('UPDATE store_verifications SET status = ? WHERE id = ?', ['denied', id]);
    await db.execute('UPDATE stores SET is_verified = ? WHERE id = ?', [false, storeId]);

    res.json({ success: true, message: 'Store denied' });
  } catch (error) {
    console.error('Error denying store:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// --- ADOPTIONS ---
exports.getAdoptions = async (req, res) => {
  try {
    const [adoptions] = await db.execute('SELECT * FROM adoptions ORDER BY created_at DESC');
    res.json({ success: true, adoptions });
  } catch (error) {
    console.error('Error fetching adoptions:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.addAdoption = async (req, res) => {
  const { name, description, breed, age, species, image_url, status } = req.body;
  try {
    await db.execute(
      'INSERT INTO adoptions (name, description, breed, age, species, image_url, status) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [name, description, breed, age, species, image_url || '', status || 'available']
    );
    res.json({ success: true, message: 'Adoption added' });
  } catch (error) {
    console.error('Error adding adoption:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.updateAdoptionStatus = async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;
  try {
    await db.execute('UPDATE adoptions SET status = ? WHERE id = ?', [status, id]);
    res.json({ success: true, message: 'Adoption status updated' });
  } catch (error) {
    console.error('Error updating adoption:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// --- MARKETPLACE ORDERS (OVERSIGHT) ---
exports.getMarketplaceOrders = async (req, res) => {
  try {
    const [orders] = await db.execute(`
      SELECT o.id as order_id, o.total_price, o.status, u.username as buyer_name, s.name as merchant_name
      FROM orders o
      JOIN users u ON o.user_id = u.id
      JOIN stores s ON o.store_id = s.id
      ORDER BY o.created_at DESC
      LIMIT 50
    `);
    res.json({ success: true, orders });
  } catch (error) {
    console.error('Error fetching marketplace orders:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// --- GENERAL USERS ---
exports.getDashboardStats = async (req, res) => {
  try {
    const [users] = await db.execute('SELECT COUNT(*) as count FROM users');
    const [verifs] = await db.execute('SELECT COUNT(*) as count FROM vet_verifications WHERE status = ?', ['pending']);
    const [posts] = await db.execute('SELECT COUNT(*) as count FROM posts');
    
    res.json({
      success: true,
      stats: {
        activeUsers: users[0].count,
        verificationQueue: verifs[0].count,
        totalPosts: posts[0].count
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
