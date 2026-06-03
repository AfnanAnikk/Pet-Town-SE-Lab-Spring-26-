const db = require('../config/db');

exports.getAllAdoptions = async (req, res) => {
  try {
    const [adoptions] = await db.execute(`
      SELECT a.*, u.profile_picture_url, u.username
      FROM adoptions a
      JOIN users u ON a.user_id = u.id
      WHERE a.status = 'available'
      ORDER BY a.created_at DESC
    `);
    res.json(adoptions);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching adoptions' });
  }
};

exports.getOwnerAdoptionRequests = async (req, res) => {
  try {
    const [requests] = await db.execute(`
      SELECT 
        r.id as request_id,
        r.status as request_status,
        r.requester_name,
        r.requester_phone,
        r.requester_address,
        r.pickup_date,
        r.created_at as requested_at,
        a.id as adoption_id,
        a.pet_name,
        a.pet_type,
        a.pet_breed,
        a.pet_age,
        a.image_url,
        u.id as requester_user_id,
        u.username as requester_username,
        u.profile_picture_url as requester_profile_picture_url
      FROM adoption_requests r
      JOIN adoptions a ON r.adoption_id = a.id
      JOIN users u ON r.user_id = u.id
      WHERE a.user_id = ?
      ORDER BY r.created_at DESC
    `, [req.params.userId]);

    res.json(requests);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching owner adoption requests' });
  }
};

exports.getAdoptionById = async (req, res) => {
  try {
    const [adoptions] = await db.execute(`
      SELECT a.*, u.profile_picture_url, u.username
      FROM adoptions a
      JOIN users u ON a.user_id = u.id
      WHERE a.id = ?
    `, [req.params.id]);
    
    if (adoptions.length === 0) {
      return res.status(404).json({ message: 'Adoption not found' });
    }
    res.json(adoptions[0]);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getUserAdoptionRequests = async (req, res) => {
  try {
    const [requests] = await db.execute(`
      SELECT 
        r.id as request_id,
        r.status as request_status,
        r.created_at as requested_at,
        a.*,
        owner.id as owner_user_id,
        owner.username as owner_username,
        owner.profile_picture_url as owner_profile_picture_url
      FROM adoption_requests r
      JOIN adoptions a ON r.adoption_id = a.id
      JOIN users owner ON a.user_id = owner.id
      WHERE r.user_id = ?
      ORDER BY r.created_at DESC
    `, [req.params.userId]);

    res.json(requests);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching requests' });
  }
};

exports.createAdoption = async (req, res) => {
  const {
    user_id, pet_name, pet_type, pet_breed, pet_age, 
    pet_traits, pet_gender, pet_food_habit, 
    owner_name, owner_contact, description, image_url
  } = req.body;

  try {
    const [result] = await db.execute(`
      INSERT INTO adoptions (
        user_id, pet_name, pet_type, pet_breed, pet_age, 
        pet_traits, pet_gender, pet_food_habit, 
        owner_name, owner_contact, description, image_url
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      user_id, pet_name, pet_type || '', pet_breed || '', pet_age || '',
      pet_traits || '', pet_gender || '', pet_food_habit || '',
      owner_name || '', owner_contact || '', description || '', image_url || ''
    ]);

    res.status(201).json({ message: 'Adoption posted successfully', id: result.insertId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error creating adoption' });
  }
};

exports.requestAdoption = async (req, res) => {
  const {
    user_id,
    requester_name,
    requester_phone,
    requester_address,
    pickup_date
  } = req.body;

  const adoption_id = req.params.id;
  
  try {
    const [existing] = await db.execute(
      'SELECT 1 FROM adoption_requests WHERE user_id = ? AND adoption_id = ?',
      [user_id, adoption_id]
    );

    if (existing.length > 0) {
      return res.status(400).json({ message: 'You have already requested this adoption' });
    }
    
    await db.execute(
      `INSERT INTO adoption_requests 
      (user_id, adoption_id, requester_name, requester_phone, requester_address, pickup_date) 
      VALUES (?, ?, ?, ?, ?, ?)`,
      [user_id, adoption_id, requester_name, requester_phone, requester_address, pickup_date]
    );

    res.status(201).json({ message: 'Adoption requested successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error requesting adoption' });
  }
};
