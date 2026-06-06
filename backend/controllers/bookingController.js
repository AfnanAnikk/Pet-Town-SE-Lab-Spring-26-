const db = require('../config/db');

exports.createBooking = async (req, res) => {
  const { userId, vetId, petName, petSpecies, petBreed, petSex, petAge, concern, reason, paymentMethod, slotTime, bookingDate, voucherCode, discountAmount } = req.body;

  try {
    const [result] = await db.execute(
      `INSERT INTO bookings (user_id, vet_id, pet_name, pet_species, pet_breed, pet_sex, pet_age, concern, reason, payment_method, slot_time, booking_date, voucher_code, discount_amount) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        userId, 
        vetId, 
        petName, 
        petSpecies, 
        petBreed, 
        petSex, 
        petAge, 
        concern, 
        reason, 
        paymentMethod, 
        slotTime, 
        bookingDate || new Date().toISOString().split('T')[0],
        voucherCode || null,
        discountAmount || 0
      ]
    );

    if (voucherCode) {
      await db.execute('UPDATE vet_vouchers SET used_count = used_count + 1 WHERE vet_id = ? AND LOWER(code) = LOWER(?)', [vetId, voucherCode.trim()]);
    }

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
        v.name AS vet_name, 
        v.service_type,
        v.user_id AS provider_user_id,
        u.profile_picture_url AS profile_picture_url,
        CASE 
          WHEN vr.id IS NULL THEN false 
          ELSE true 
        END AS has_reviewed
      FROM bookings b 
      JOIN vets v ON b.vet_id = v.id
      JOIN users u ON v.user_id = u.id
      LEFT JOIN vet_reviews vr 
        ON vr.booking_id = b.id
      WHERE b.user_id = ? 
      ORDER BY b.id DESC
    `, [userId]);

    res.json(bookings);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getVetBookings = async (req, res) => {
  const vetUserId = req.params.userId;
  try {
    // First get the vet id for this user
    const [vets] = await db.execute('SELECT id FROM vets WHERE user_id = ?', [vetUserId]);
    if (vets.length === 0) {
      return res.status(404).json({ message: 'Vet not found' });
    }
    const vetId = vets[0].id;

    // Then get bookings for this vet
    const [bookings] = await db.execute(`
      SELECT b.*, u.username as user_name, u.email as user_email
      FROM bookings b 
      JOIN users u ON b.user_id = u.id 
      WHERE b.vet_id = ? 
      ORDER BY b.id DESC
    `, [vetId]);
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
    await db.execute('UPDATE bookings SET status = ? WHERE id = ?', [status, bookingId]);

    // Notification Trigger (Phase 4)
    if (status === 'accepted') {
      const [booking] = await db.execute('SELECT user_id, pet_name FROM bookings WHERE id = ?', [bookingId]);
      if (booking.length > 0) {
        await db.execute(
          'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
          [booking[0].user_id, 'order', bookingId, `Your vet booking for ${booking[0].pet_name} was accepted!`]
        );
      }
    } else if (status === 'completed') {
      const [booking] = await db.execute('SELECT user_id, pet_name FROM bookings WHERE id = ?', [bookingId]);
      if (booking.length > 0) {
        await db.execute(
          'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
          [booking[0].user_id, 'order', bookingId, `Your vet booking for ${booking[0].pet_name} is completed! Please leave a review.`]
        );
      }
    }

    res.json({ message: 'Booking status updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating booking status' });
  }
};
