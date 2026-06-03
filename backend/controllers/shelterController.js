const db = require('../config/db');

exports.getAllShelters = async (req, res) => {
  try {
    const [shelters] = await db.execute('SELECT * FROM shelters ORDER BY id ASC');
    res.json(shelters);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching shelters' });
  }
};

exports.getShelterById = async (req, res) => {
  try {
    const [shelters] = await db.execute('SELECT * FROM shelters WHERE id = ?', [req.params.id]);
    if (shelters.length === 0) {
      return res.status(404).json({ message: 'Shelter not found' });
    }
    res.json(shelters[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.bookShelter = async (req, res) => {
  const shelter_id = req.params.id;
  const { user_id, pet_type, pet_name, from_date, to_date } = req.body;

  try {
    await db.execute(`
      INSERT INTO shelter_bookings (
        user_id, shelter_id, pet_type, pet_name, from_date, to_date
      ) VALUES (?, ?, ?, ?, ?, ?)
    `, [user_id, shelter_id, pet_type || '', pet_name || '', from_date || '', to_date || '']);

    res.status(201).json({ message: 'Shelter booked successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error booking shelter' });
  }
};

exports.getUserShelterBookings = async (req, res) => {
  try {
    const [bookings] = await db.execute(`
      SELECT b.*, s.name as shelter_name, s.location as shelter_location 
      FROM shelter_bookings b
      JOIN shelters s ON b.shelter_id = s.id
      WHERE b.user_id = ?
      ORDER BY b.created_at DESC
    `, [req.params.userId]);
    res.json(bookings);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching bookings' });
  }
};
