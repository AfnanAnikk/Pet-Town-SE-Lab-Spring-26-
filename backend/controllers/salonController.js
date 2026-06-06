const db = require('../config/db');

exports.getAllSalons = async (req, res) => {
  try {
    const { location, concern } = req.query;
    let query = 'SELECT DISTINCT s.*, u.profile_picture_url as owner_picture FROM salons s JOIN users u ON s.user_id = u.id';
    let params = [];
    let conditions = [];

    // Verified only for public listing
    conditions.push('s.is_verified = true');

    if (location) {
      conditions.push('LOWER(s.location) LIKE ?');
      params.push(`%${location.toLowerCase()}%`);
    }

    if (concern) { // used as a tag filter
      query += ' JOIN salon_tags t ON s.id = t.salon_id';
      conditions.push('t.tag = ?');
      params.push(concern);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    const [salons] = await db.execute(query, params);
    
    // Fetch tags and slots for each salon
    for (let salon of salons) {
      const [tags] = await db.execute('SELECT tag FROM salon_tags WHERE salon_id = ?', [salon.id]);
      const [slots] = await db.execute('SELECT slot_time FROM salon_slots WHERE salon_id = ?', [salon.id]);
      const [reviews] = await db.execute('SELECT r.*, u.display_name as author_name FROM salon_reviews r JOIN users u ON r.user_id = u.id WHERE r.salon_id = ? ORDER BY r.created_at DESC', [salon.id]);

      salon.tags = tags.map(t => t.tag);
      salon.availableSlots = slots.map(s => s.slot_time);
      salon.reviews = reviews;
    }

    res.json(salons);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getSalonById = async (req, res) => {
  const salonId = req.params.id;
  try {
    const [salons] = await db.execute('SELECT s.*, u.profile_picture_url as owner_picture FROM salons s JOIN users u ON s.user_id = u.id WHERE s.id = ?', [salonId]);
    
    if (salons.length === 0) return res.status(404).json({ message: 'Salon not found' });

    const salon = salons[0];
    const [tags] = await db.execute('SELECT tag FROM salon_tags WHERE salon_id = ?', [salonId]);
    const [slots] = await db.execute('SELECT slot_time FROM salon_slots WHERE salon_id = ?', [salonId]);
    const [reviews] = await db.execute('SELECT r.*, u.display_name as author_name FROM salon_reviews r JOIN users u ON r.user_id = u.id WHERE r.salon_id = ? ORDER BY r.created_at DESC', [salonId]);

    salon.tags = tags.map(t => t.tag);
    salon.availableSlots = slots.map(s => s.slot_time);
    salon.reviews = reviews;

    res.json(salon);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getSalonByUserId = async (req, res) => {
  const userId = req.params.userId;
  try {
    const [salons] = await db.execute('SELECT s.*, u.profile_picture_url as owner_picture FROM salons s JOIN users u ON s.user_id = u.id WHERE s.user_id = ?', [userId]);
    
    if (salons.length === 0) return res.status(404).json({ message: 'Salon profile not found' });

    const salon = salons[0];
    const salonId = salon.id;

    const [tags] = await db.execute('SELECT tag FROM salon_tags WHERE salon_id = ?', [salonId]);
    const [slots] = await db.execute('SELECT slot_time FROM salon_slots WHERE salon_id = ?', [salonId]);

    salon.tags = tags.map(t => t.tag);
    salon.availableSlots = slots.map(s => s.slot_time);

    res.json(salon);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', success: false });
  }
};

exports.updateSalonProfile = async (req, res) => {
  const { 
    userId, name, ownerName, location, price, profileDescription, profilePictureUrl,
    tags, availableSlots 
  } = req.body;

  try {
    if (profilePictureUrl) {
      // Though image might be for the salon, we might also just store it on the salon table directly instead of user
      await db.execute('UPDATE salons SET profile_picture_url = ? WHERE user_id = ?', [profilePictureUrl, userId]);
    }
    
    const [existing] = await db.execute('SELECT id FROM salons WHERE user_id = ?', [userId]);
    let salonId;
    
    if (existing.length === 0) {
      const [result] = await db.execute(
        'INSERT INTO salons (user_id, name, owner_name, location, price, profile_description, profile_picture_url, is_verified) VALUES (?, ?, ?, ?, ?, ?, ?, true)',
        [userId, name, ownerName, location, price, profileDescription, profilePictureUrl]
      );
      salonId = result.insertId;
    } else {
      salonId = existing[0].id;
      await db.execute(
        'UPDATE salons SET name = ?, owner_name = ?, location = ?, price = ?, profile_description = ?, profile_picture_url = COALESCE(?, profile_picture_url) WHERE id = ?',
        [name, ownerName, location, price, profileDescription, profilePictureUrl, salonId]
      );
    }

    await db.execute('DELETE FROM salon_tags WHERE salon_id = ?', [salonId]);
    await db.execute('DELETE FROM salon_slots WHERE salon_id = ?', [salonId]);

    if (tags && tags.length > 0) {
      for (const t of tags) await db.execute('INSERT INTO salon_tags (salon_id, tag) VALUES (?, ?)', [salonId, t]);
    }
    if (availableSlots && availableSlots.length > 0) {
      for (const slot of availableSlots) await db.execute('INSERT INTO salon_slots (salon_id, slot_time) VALUES (?, ?)', [salonId, slot]);
    }

    res.json({ message: 'Profile updated successfully', success: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', success: false });
  }
};

// Bookings
exports.createBooking = async (req, res) => {
  const { userId, salonId, petName, petSpecies, petBreed, petSex, petAge, concern, reason, paymentMethod, slotTime, bookingDate, voucherCode, discountAmount } = req.body;

  try {
    const [result] = await db.execute(
      `INSERT INTO salon_bookings (user_id, salon_id, pet_name, pet_species, pet_breed, pet_sex, pet_age, concern, reason, payment_method, slot_time, booking_date, voucher_code, discount_amount) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, salonId, petName, petSpecies, petBreed, petSex, petAge, concern, reason, paymentMethod, slotTime, bookingDate || new Date().toISOString().split('T')[0], voucherCode || null, discountAmount || 0]
    );

    if (voucherCode) {
      await db.execute('UPDATE salon_vouchers SET used_count = used_count + 1 WHERE salon_id = ? AND LOWER(code) = LOWER(?)', [salonId, voucherCode.trim()]);
    }
    
    await db.execute('UPDATE salons SET total_bookings = total_bookings + 1 WHERE id = ?', [salonId]);

    res.status(201).json({ message: 'Booking created successfully', bookingId: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getUserBookings = async (req, res) => {
  const userId = req.params.userId;

  try {
    const [bookings] = await db.execute(`
      SELECT
        b.*,
        s.name AS salon_name,
        s.profile_picture_url AS profile_picture_url,
        CASE 
          WHEN sr.id IS NULL THEN false 
          ELSE true 
        END AS has_reviewed
      FROM salon_bookings b
      JOIN salons s ON b.salon_id = s.id
      LEFT JOIN salon_reviews sr 
        ON sr.salon_id = b.salon_id 
        AND sr.user_id = b.user_id
      WHERE b.user_id = ?
      ORDER BY b.id DESC
    `, [userId]);

    res.json(bookings);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getProviderBookings = async (req, res) => {
  const providerUserId = req.params.userId;
  try {
    const [salons] = await db.execute('SELECT id FROM salons WHERE user_id = ?', [providerUserId]);
    if (salons.length === 0) return res.status(404).json({ message: 'Salon not found' });
    
    const salonId = salons[0].id;
    const [bookings] = await db.execute(`
      SELECT b.*, u.username as user_name, u.email as user_email
      FROM salon_bookings b 
      JOIN users u ON b.user_id = u.id 
      WHERE b.salon_id = ? 
      ORDER BY b.id DESC
    `, [salonId]);
    res.json(bookings);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.updateBookingStatus = async (req, res) => {
  const bookingId = req.params.id;
  const { status } = req.body;
  try {
    await db.execute('UPDATE salon_bookings SET status = ? WHERE id = ?', [status, bookingId]);

    // Notification Trigger
    if (status === 'accepted') {
      const [booking] = await db.execute('SELECT user_id, pet_name FROM salon_bookings WHERE id = ?', [bookingId]);
      if (booking.length > 0) {
        await db.execute(
          'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
          [booking[0].user_id, 'order', bookingId, `Your salon booking for ${booking[0].pet_name} was accepted!`]
        );
      }
    } else if (status === 'completed') {
      const [booking] = await db.execute('SELECT user_id, pet_name FROM salon_bookings WHERE id = ?', [bookingId]);
      if (booking.length > 0) {
        await db.execute(
          'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
          [booking[0].user_id, 'order', bookingId, `Your salon booking for ${booking[0].pet_name} is completed! Please leave a review.`]
        );
      }
    }

    res.json({ message: 'Booking status updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating booking status' });
  }
};

// Vouchers
exports.getVouchers = async (req, res) => {
  const providerUserId = req.params.userId;
  try {
    const [salons] = await db.execute('SELECT id FROM salons WHERE user_id = ?', [providerUserId]);
    if (salons.length === 0) return res.status(404).json({ message: 'Salon not found' });
    
    const salonId = salons[0].id;
    const [vouchers] = await db.execute('SELECT * FROM salon_vouchers WHERE salon_id = ?', [salonId]);
    res.json(vouchers);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.createVoucher = async (req, res) => {
  const providerUserId = req.params.userId;
  const { code, discountPercent, maxUses, expiresAt } = req.body;
  try {
    const [salons] = await db.execute('SELECT id FROM salons WHERE user_id = ?', [providerUserId]);
    if (salons.length === 0) return res.status(404).json({ message: 'Salon not found' });
    
    const salonId = salons[0].id;
    await db.execute(
      'INSERT INTO salon_vouchers (salon_id, code, discount_percent, max_uses, expires_at) VALUES (?, ?, ?, ?, ?)',
      [salonId, code, discountPercent, maxUses, expiresAt]
    );
    res.status(201).json({ message: 'Voucher created successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.deleteVoucher = async (req, res) => {
  const voucherId = req.params.id;
  try {
    await db.execute('DELETE FROM salon_vouchers WHERE id = ?', [voucherId]);
    res.json({ message: 'Voucher deleted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.validateVoucher = async (req, res) => {
  const { code, salonId } = req.body;
  try {
    const [vouchers] = await db.execute(
      'SELECT * FROM salon_vouchers WHERE salon_id = ? AND LOWER(code) = LOWER(?) AND is_active = true', 
      [salonId, code.trim()]
    );
    
    if (vouchers.length === 0) {
      return res.status(400).json({ success: false, message: 'Invalid or inactive voucher code' });
    }

    const voucher = vouchers[0];
    if (voucher.used_count >= voucher.max_uses) {
      return res.status(400).json({ success: false, message: 'Voucher usage limit reached' });
    }

    if (voucher.expires_at && new Date(voucher.expires_at) < new Date()) {
      return res.status(400).json({ success: false, message: 'Voucher has expired' });
    }

    res.json({ success: true, discountPercent: voucher.discount_percent });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.addSalonReview = async (req, res) => {
  const salonId = req.params.id;
  const { userId, bookingId, rating, reviewText } = req.body;

  try {
    // 1. Insert the review
    await db.execute(
      'INSERT INTO salon_reviews (booking_id, salon_id, user_id, rating, review_text) VALUES (?, ?, ?, ?, ?)',
      [bookingId, salonId, userId, rating, reviewText]
    );
    if (error.code === '23505') {
      return res.status(400).json({
        success: false,
        message: 'You have already reviewed this booking',
      });
    }

    // 2. Calculate new average rating and review count
    const [stats] = await db.execute(
      'SELECT AVG(rating) as avg_rating, COUNT(*) as review_count FROM salon_reviews WHERE salon_id = ?',
      [salonId]
    );

    const newRating = stats[0].avg_rating ? parseFloat(stats[0].avg_rating).toFixed(1) : 0;
    const newCount = stats[0].review_count || 0;

    // 3. Update the salons table
    await db.execute(
      'UPDATE salons SET rating = ?, review_count = ? WHERE id = ?',
      [newRating, newCount, salonId]
    );

    res.json({ success: true, message: 'Review added successfully', data: { rating: newRating, reviewCount: newCount } });
  } catch (error) {
    console.error('Error adding salon review:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

