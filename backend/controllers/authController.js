const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your_super_secret_key';

exports.register = async (req, res) => {
  const { username, email, password, phone_number, role, name, service_type, degree, is_verified, rating, review_count, price, profile_description } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  try {
    // Check if user exists
    const [existingUsers] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole = role === 'service_provider' ? 'service_provider' : 'user';

    // Insert user
    const [userResult] = await db.execute(
      'INSERT INTO users (username, email, password_hash, phone_number, role) VALUES (?, ?, ?, ?, ?)',
      [username || null, email, hashedPassword, phone_number || null, userRole]
    );

    const userId = userResult.insertId;

    // If service provider, insert into vets table
    if (userRole === 'service_provider') {
      await db.execute(
        'INSERT INTO vets (user_id, name, service_type, degree, is_verified, rating, review_count, price, profile_description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [userId, name || '', service_type || '', degree || '', is_verified || false, rating || 0.0, review_count || 0, price || 0, profile_description || '']
      );
    }

    res.status(201).json({ message: 'User registered successfully', userId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  try {
    const [users] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (users.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);

    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const payload = {
      user: {
        id: user.id,
        role: user.role
      }
    };

    jwt.sign(payload, JWT_SECRET, { expiresIn: '1h' }, (err, token) => {
      if (err) throw err;
      res.json({ token, user: { id: user.id, username: user.username, email: user.email, role: user.role } });
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};
