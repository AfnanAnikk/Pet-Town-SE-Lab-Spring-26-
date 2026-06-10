const db = require('../config/db');

// --- FINANCE ---
exports.getFinanceStats = async (req, res) => {
  try {
    const [vetBookings] = await db.execute(`
      SELECT SUM(v.price) as total_vet_revenue 
      FROM bookings b 
      JOIN vets v ON b.vet_id = v.id 
      WHERE b.status != 'cancelled'
    `);

    const [salonBookings] = await db.execute(`
      SELECT SUM(s.price) as total_salon_revenue
      FROM salon_bookings sb
      JOIN salons s ON sb.salon_id = s.id
      WHERE sb.status != 'cancelled'
    `);
    
    const [orders] = await db.execute(`
      SELECT SUM(total_price) as total_marketplace_gmv 
      FROM orders 
      WHERE status != 'cancelled'
    `);

    const vetRevenue = Number(vetBookings[0].total_vet_revenue) || 0;
    const salonRevenue = Number(salonBookings[0].total_salon_revenue) || 0;
    const marketplaceGMV = Number(orders[0].total_marketplace_gmv) || 0;

    const vetCommission = vetRevenue * 0.10;
    const salonCommission = salonRevenue * 0.10;
    const marketplaceCommission = marketplaceGMV * 0.08;

    const serviceCommissions = vetCommission + salonCommission;
    const totalNetRevenue = serviceCommissions + marketplaceCommission;
    
    res.json({
      success: true,
      stats: {
        totalNetRevenue,
        adRevenue: 45200,
        serviceCommissions,
        vetCommission,
        salonCommission,
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

    const [vetVerifs] = await db.execute(
      'SELECT COUNT(*) as count FROM vet_verifications WHERE status = ?',
      ['pending']
    );

    const [storeVerifs] = await db.execute(
      'SELECT COUNT(*) as count FROM store_verifications WHERE status = ?',
      ['pending']
    );

    const [salonVerifs] = await db.execute(
      'SELECT COUNT(*) as count FROM salon_verifications WHERE status = ?',
      ['pending']
    );

    const [posts] = await db.execute('SELECT COUNT(*) as count FROM posts');
    
    res.json({
      success: true,
      stats: {
        activeUsers: users[0].count,
        verificationQueue:
          Number(vetVerifs[0].count || 0) +
          Number(storeVerifs[0].count || 0) +
          Number(salonVerifs[0].count || 0),
        totalPosts: posts[0].count
      }
    });
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};


exports.getSalonVerifications = async (req, res) => {
  try {
    const [verifications] = await db.execute(`
      SELECT sv.*, s.name as salon_name, s.location, u.email
      FROM salon_verifications sv
      JOIN salons s ON sv.salon_id = s.id
      JOIN users u ON s.user_id = u.id
      ORDER BY sv.created_at DESC
    `);

    res.json({ success: true, verifications });
  } catch (error) {
    console.error('Error fetching salon verifications:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.approveSalon = async (req, res) => {
  const { id } = req.params;

  try {
    const [verifs] = await db.execute(
      'SELECT salon_id FROM salon_verifications WHERE id = ?',
      [id]
    );

    if (verifs.length === 0) {
      return res.status(404).json({ success: false, message: 'Verification not found' });
    }

    const salonId = verifs[0].salon_id;

    await db.execute('UPDATE salon_verifications SET status = ? WHERE id = ?', ['approved', id]);
    await db.execute('UPDATE salons SET is_verified = ? WHERE id = ?', [true, salonId]);

    res.json({ success: true, message: 'Salon approved' });
  } catch (error) {
    console.error('Error approving salon:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.denySalon = async (req, res) => {
  const { id } = req.params;

  try {
    const [verifs] = await db.execute(
      'SELECT salon_id FROM salon_verifications WHERE id = ?',
      [id]
    );

    if (verifs.length === 0) {
      return res.status(404).json({ success: false, message: 'Verification not found' });
    }

    const salonId = verifs[0].salon_id;

    await db.execute('UPDATE salon_verifications SET status = ? WHERE id = ?', ['denied', id]);
    await db.execute('UPDATE salons SET is_verified = ? WHERE id = ?', [false, salonId]);

    res.json({ success: true, message: 'Salon denied' });
  } catch (error) {
    console.error('Error denying salon:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getModerationAlerts = async (req, res) => {
  try {
    const [alerts] = await db.execute(`
      SELECT 
        ma.*,
        p.title,
        p.description,
        p.author_name,
        u.username,
        u.display_name,
        u.email,
        u.profile_picture_url
      FROM moderation_alerts ma
      JOIN posts p ON ma.post_id = p.id
      JOIN users u ON ma.user_id = u.id
      WHERE ma.status = 'pending'
      ORDER BY ma.created_at DESC
    `);

    res.json({ success: true, alerts });
  } catch (error) {
    console.error('Error fetching moderation alerts:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.deleteFlaggedPost = async (req, res) => {
  const { id } = req.params;

  try {
    const [alerts] = await db.execute('SELECT post_id FROM moderation_alerts WHERE id = ?', [id]);
    if (alerts.length === 0) return res.status(404).json({ success: false, message: 'Alert not found' });

    await db.execute('DELETE FROM posts WHERE id = ?', [alerts[0].post_id]);
    await db.execute('UPDATE moderation_alerts SET status = ? WHERE id = ?', ['post_deleted', id]);

    res.json({ success: true, message: 'Post deleted' });
  } catch (error) {
    console.error('Error deleting flagged post:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.warnFlaggedUser = async (req, res) => {
  const { id } = req.params;

  try {
    const [alerts] = await db.execute('SELECT user_id, post_id FROM moderation_alerts WHERE id = ?', [id]);
    if (alerts.length === 0) return res.status(404).json({ success: false, message: 'Alert not found' });

    const { user_id, post_id } = alerts[0];

    await db.execute('UPDATE users SET warning_count = COALESCE(warning_count, 0) + 1 WHERE id = ?', [user_id]);

    await db.execute(
      'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
      [user_id, 'warning', post_id, 'Your post may not contain pet-related content. Please keep posts relevant to pets.']
    );

    await db.execute('UPDATE moderation_alerts SET status = ? WHERE id = ?', ['user_warned', id]);

    res.json({ success: true, message: 'User warned' });
  } catch (error) {
    console.error('Error warning user:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.banFlaggedUser = async (req, res) => {
  const { id } = req.params;

  try {
    const [alerts] = await db.execute('SELECT user_id FROM moderation_alerts WHERE id = ?', [id]);
    if (alerts.length === 0) return res.status(404).json({ success: false, message: 'Alert not found' });

    await db.execute('UPDATE users SET is_banned = true WHERE id = ?', [alerts[0].user_id]);
    await db.execute('UPDATE moderation_alerts SET status = ? WHERE id = ?', ['user_banned', id]);

    res.json({ success: true, message: 'User banned' });
  } catch (error) {
    console.error('Error banning user:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.dismissModerationAlert = async (req, res) => {
  const { id } = req.params;

  try {
    await db.execute('UPDATE moderation_alerts SET status = ? WHERE id = ?', ['dismissed', id]);
    res.json({ success: true, message: 'Alert dismissed' });
  } catch (error) {
    console.error('Error dismissing moderation alert:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};