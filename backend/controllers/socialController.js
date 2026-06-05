const db = require('../config/db');

// Follow a user
exports.followUser = async (req, res) => {
  const { followerId, followingId } = req.body;
  if (followerId === followingId) {
    return res.status(400).json({ success: false, message: 'You cannot follow yourself' });
  }

  try {
    // Check if already following
    const [existing] = await db.execute(
      'SELECT id FROM follows WHERE follower_id = ? AND following_id = ?',
      [followerId, followingId]
    );

    if (existing.length > 0) {
      return res.status(400).json({ success: false, message: 'Already following this user' });
    }

    await db.execute(
      'INSERT INTO follows (follower_id, following_id) VALUES (?, ?)',
      [followerId, followingId]
    );

    // Phase 4 trigger: Create a notification for the user being followed
    await db.execute(
      'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
      [followingId, 'follow', followerId, 'Someone started following you!'] // We'll update the message when we get the follower's name later
    );

    res.json({ success: true, message: 'Successfully followed user' });
  } catch (error) {
    console.error('Error following user:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Unfollow a user
exports.unfollowUser = async (req, res) => {
  const { followerId, followingId } = req.body;

  try {
    await db.execute(
      'DELETE FROM follows WHERE follower_id = ? AND following_id = ?',
      [followerId, followingId]
    );
    res.json({ success: true, message: 'Successfully unfollowed user' });
  } catch (error) {
    console.error('Error unfollowing user:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Check follow status
exports.getFollowStatus = async (req, res) => {
  const { followerId, followingId } = req.query;
  
  if (!followerId || !followingId) {
    return res.status(400).json({ success: false, message: 'Missing parameters' });
  }

  try {
    const [follows] = await db.execute(
      'SELECT id FROM follows WHERE follower_id = ? AND following_id = ?',
      [followerId, followingId]
    );
    res.json({ success: true, isFollowing: follows.length > 0 });
  } catch (error) {
    console.error('Error checking follow status:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Global Search (Phase 3)
exports.globalSearch = async (req, res) => {
  const { q } = req.query;
  if (!q) {
    return res.json({ success: true, users: [], posts: [] });
  }

  try {
    if (q.startsWith('@')) {
      // Search ONLY users
      const searchTerm = `%${q.substring(1)}%`;
      const [users] = await db.execute(
        'SELECT id, username, display_name as name, email, role, profile_picture_url FROM users WHERE display_name ILIKE ? OR email ILIKE ? OR username ILIKE ? LIMIT 20',
        [searchTerm, searchTerm, searchTerm]
      );
      return res.json({ success: true, users: users, posts: [] });
    } else {
      // Search BOTH users and posts
      const searchTerm = `%${q}%`;
      const [users] = await db.execute(
        'SELECT id, username, display_name as name, email, role, profile_picture_url FROM users WHERE display_name ILIKE ? OR email ILIKE ? OR username ILIKE ? LIMIT 20',
        [searchTerm, searchTerm, searchTerm]
      );

      const [posts] = await db.execute(`
        SELECT p.*,
               u.profile_picture_url,
               COALESCE(u.username, u.display_name, p.author_name) AS author_name
        FROM posts p
        JOIN users u ON p.user_id = u.id
        WHERE p.title ILIKE ?
        OR EXISTS (
          SELECT 1 FROM post_tags pt WHERE pt.post_id = p.id AND pt.tag_name ILIKE ?
        )
        LIMIT 20
      `, [searchTerm, searchTerm]);

      for (let post of posts) {
        const [tags] = await db.execute('SELECT tag_name FROM post_tags WHERE post_id = ?', [post.id]);
        post.tags = tags.map(t => t.tag_name);
      }

      return res.json({ success: true, users: users, posts: posts });
    }
  } catch (error) {
    console.error('Error searching:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Get Notifications
exports.getNotifications = async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ success: false, message: 'User ID required' });

  try {
    const [notifications] = await db.execute(
      'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50',
      [userId]
    );

    // Mark as read
    await db.execute('UPDATE notifications SET is_read = true WHERE user_id = ? AND is_read = false', [userId]);

    res.json(notifications);
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Get Unread Notifications Count
exports.getUnreadNotificationsCount = async (req, res) => {
  const { userId } = req.query;
  if (!userId) return res.status(400).json({ success: false, message: 'User ID required' });

  try {
    const [rows] = await db.execute(
      'SELECT COUNT(*)::int as count FROM notifications WHERE user_id = ? AND is_read = false',
      [userId]
    );
    res.json({ success: true, count: rows[0].count || 0 });
  } catch (error) {
    console.error('Error fetching unread count:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

