const db = require('../config/db');

exports.createBooking = async (req, res) => {
  const { userId, vetId, petName, petSpecies, petBreed, petSex, petAge, concern, reason, paymentMethod, slotTime, bookingDate } = req.body;

  try {
    const [result] = await db.execute(
      `INSERT INTO bookings (user_id, vet_id, pet_name, pet_species, pet_breed, pet_sex, pet_age, concern, reason, payment_method, slot_time, booking_date) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, vetId, petName, petSpecies, petBreed, petSex, petAge, concern, reason, paymentMethod, slotTime, bookingDate || new Date().toISOString().split('T')[0]]
    );

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
      SELECT b.*, v.name as vet_name, v.service_type 
      FROM bookings b 
      JOIN vets v ON b.vet_id = v.id 
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
    res.json({ message: 'Booking status updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};
