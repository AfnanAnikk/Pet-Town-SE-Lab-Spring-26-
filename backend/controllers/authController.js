const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'your_super_secret_key';

exports.register = async (req, res) => {
  const { username, email, password, phone_number, role, name, service_type, degree, is_verified, rating, review_count, price, profile_description } = req.body;

  if (!email || !password) {
    return res.status(400).json({ message: 'Email and password are required' });
  }

  try {
    const [existingUsers] = await db.execute('SELECT * FROM users WHERE email = ?', [email]);
    if (existingUsers.length > 0) {
      return res.status(400).json({ message: 'User already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userRole = role === 'service_provider' ? 'service_provider' : 'user';
    const userServiceType = userRole === 'service_provider' ? (service_type || '') : null;

    // Insert user with service_type stored directly
    const [userResult] = await db.execute(
      'INSERT INTO users (username, email, password_hash, phone_number, role, service_type) VALUES (?, ?, ?, ?, ?, ?)',
      [username || null, email, hashedPassword, phone_number || null, userRole, userServiceType]
    );

    const userId = userResult.insertId;

    // If service provider, insert into vets or stores table based on service_type
    if (userRole === 'service_provider') {
      if (service_type === 'Marketplace Owner') {
        await db.execute(
          'INSERT INTO stores (user_id, name, description, category, banner_color, location, banner_url, contact_info, is_verified, rating, review_count) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [userId, name || '', profile_description || '', 'General', '#3293B3', '', null, '', false, 0.0, 0]
        );
      } else {
        await db.execute(
          'INSERT INTO vets (user_id, name, service_type, degree, is_verified, rating, review_count, price, profile_description) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [userId, name || '', service_type || '', degree || '', is_verified || false, rating || 0.0, review_count || 0, price || 0, profile_description || '']
        );
      }
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

    if (user.is_banned) {
      return res.status(403).json({
        message: 'Your account has been banned.'
      });
    }

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

    jwt.sign(payload, JWT_SECRET, { expiresIn: '7d' }, (err, token) => {
      if (err) throw err;
      res.json({
        token,
        user: {
          id: user.id,
          username: user.username,
          display_name: user.display_name || null,
          email: user.email,
          role: user.role,
          service_type: user.service_type || '',
          is_banned: user.is_banned
        }
      });
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// GET /api/auth/profile/:id
exports.getProfile = async (req, res) => {
  const { id } = req.params;
  try {
    const [users] = await db.execute(
      'SELECT id, username, display_name, email, phone_number, role, service_type, profile_picture_url, is_banned FROM users WHERE id = ?',
      [id]
    );
    if (users.length === 0) return res.status(404).json({ message: 'User not found' });
    const user = users[0];

    // Count posts
    const [postCountRows] = await db.execute(
      'SELECT COUNT(*) as count FROM posts WHERE user_id = ?',
      [id]
    );
    const postCount = parseInt(postCountRows[0]?.count ?? 0);

    // Get user posts with tags
    const [posts] = await db.execute(
    `
      SELECT 
        p.*,
        u.profile_picture_url,
        COALESCE(u.display_name, u.username, p.author_name) AS author_name
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.user_id = ?
      ORDER BY p.id DESC
      `,
      [id]
    );
    for (let post of posts) {
      const [tags] = await db.execute('SELECT tag_name FROM post_tags WHERE post_id = ?', [post.id]);
      post.tags = tags.map(t => t.tag_name);
    }

    res.json({ user, postCount, posts });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

// PUT /api/auth/profile/:id
exports.updateProfile = async (req, res) => {
  const { id } = req.params;
  const { displayName, profilePictureUrl } = req.body;
  try {
    let query = 'UPDATE users SET display_name = ?';
    let params = [displayName];

    if (profilePictureUrl !== undefined) {
      query += ', profile_picture_url = ?';
      params.push(profilePictureUrl);
    }

    query += ' WHERE id = ?';
    params.push(id);

    await db.execute(query, params);
    res.json({ message: 'Profile updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error updating profile' });
  }
};

exports.getAllUsers = async (req, res) => {
  try {
    const [users] = await db.execute(
      'SELECT id, username, display_name, email, role, profile_picture_url FROM users ORDER BY username ASC'
    );
    res.json(users);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error fetching users' });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const userResult = await db.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'No account found with this email' });
    }

    const code = crypto.randomInt(100000, 999999).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await db.query(
      'UPDATE password_reset_codes SET used = true WHERE email = $1 AND used = false',
      [email]
    );

    await db.query(
      `INSERT INTO password_reset_codes (email, code, expires_at)
       VALUES ($1, $2, $3)`,
      [email, code, expiresAt]
    );

    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });

    await transporter.sendMail({
      from: `"PetTown" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'PetTown Password Reset Code',
      html: `
        <div style="font-family: Arial, sans-serif;">
          <h2>PetTown Password Reset</h2>
          <p>Your verification code is:</p>
          <h1 style="letter-spacing: 4px;">${code}</h1>
          <p>This code will expire in 10 minutes.</p>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      `,
    });

    return res.json({ message: 'Verification code sent to your email' });
  } catch (error) {
    console.error('Forgot password error:', error);
    return res.status(500).json({ message: 'Failed to send verification code' });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    if (!email || !code || !newPassword) {
      return res.status(400).json({ message: 'Email, code, and new password are required' });
    }

    if (newPassword.length < 8) {
      return res.status(400).json({ message: 'Password must be at least 8 characters' });
    }

    const codeResult = await db.query(
      `SELECT id FROM password_reset_codes
       WHERE email = $1
       AND code = $2
       AND used = false
       AND expires_at > NOW()
       ORDER BY created_at DESC
       LIMIT 1`,
      [email, code]
    );

    if (codeResult.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid or expired verification code' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await db.query(
      'UPDATE users SET password_hash = $1 WHERE email = $2',
      [hashedPassword, email]
    );

    await db.query(
      'UPDATE password_reset_codes SET used = true WHERE id = $1',
      [codeResult.rows[0].id]
    );

    return res.json({ message: 'Password reset successful' });
  } catch (error) {
    console.error('Reset password error:', error);
    return res.status(500).json({ message: 'Failed to reset password' });
  }
};
