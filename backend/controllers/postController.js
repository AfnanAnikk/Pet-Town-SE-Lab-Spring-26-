const db = require('../config/db');

exports.getAllPosts = async (req, res) => {
  try {
    const [posts] = await db.execute(`
      SELECT 
        p.*,
        u.profile_picture_url,
        COALESCE(u.username, u.display_name, p.author_name) AS author_name
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE LOWER(p.title) NOT LIKE '%test%'
      ORDER BY p.id DESC
    `);

    for (let post of posts) {
      const [tags] = await db.execute(
        'SELECT tag_name FROM post_tags WHERE post_id = ?',
        [post.id]
      );
      post.tags = tags.map(t => t.tag_name);
    }

    res.json(posts);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.createPost = async (req, res) => {
  const { user_id, title, description, author_name, image_path, placeholder_color, placeholder_height, tags } = req.body;

  if (!user_id || !title || !image_path) {
    return res.status(400).json({ message: 'user_id, title, and image_path are required' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO posts (user_id, title, description, author_name, image_path, placeholder_color, placeholder_height) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [user_id, title, description || '', author_name || '', image_path, placeholder_color || '', placeholder_height || 0.0]
    );

    const postId = result.insertId;

    if (tags && Array.isArray(tags)) {
      for (const tag of tags) {
        if (tag) await db.execute('INSERT INTO post_tags (post_id, tag_name) VALUES (?, ?)', [postId, tag]);
      }
    }

    res.status(201).json({ message: 'Post created successfully', postId });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: error.message || 'Server error creating post' });
  }
};

exports.likePost = async (req, res) => {
  const { userId } = req.body;
  const postId = req.params.id;

  try {
    const [existing] = await db.execute(
      'SELECT 1 FROM post_likes WHERE post_id = ? AND user_id = ?',
      [postId, userId]
    );

    if (existing.length > 0) {
      return res.json({ message: 'Already liked' });
    }

    await db.execute(
      'INSERT INTO post_likes (post_id, user_id) VALUES (?, ?) ON CONFLICT (post_id, user_id) DO NOTHING',
      [postId, userId]
    );

    await db.execute(
      'UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?',
      [postId]
    );

    const [post] = await db.execute(
      'SELECT user_id, title FROM posts WHERE id = ?',
      [postId]
    );

    if (post.length > 0 && post[0].user_id.toString() !== userId.toString()) {
      const [likerRows] = await db.execute(
        'SELECT COALESCE(display_name, username, email) AS name FROM users WHERE id = ?',
        [userId]
      );

      const likerName = likerRows[0]?.name || 'Someone';

      await db.execute(
        'INSERT INTO notifications (user_id, type, reference_id, message) VALUES (?, ?, ?, ?)',
        [post[0].user_id, 'like', postId, `${likerName} liked your post "${post[0].title}"!`]
      );
    }

    res.json({ message: 'Post liked' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.unlikePost = async (req, res) => {
  const { userId } = req.body;
  const postId = req.params.id;
  try {
    const [existing] = await db.execute(
      'SELECT 1 FROM post_likes WHERE post_id = ? AND user_id = ?',
      [postId, userId]
    );
    if (existing.length === 0) {
      return res.json({ message: 'Not liked' });
    }
    await db.execute('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?', [postId, userId]);
    await db.execute('UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = ?', [postId]);
    res.json({ message: 'Post unliked' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.addComment = async (req, res) => {
  const { userId, text } = req.body;
  const postId = req.params.id;
  try {
    await db.execute('INSERT INTO post_comments (post_id, user_id, text) VALUES (?, ?, ?)', [postId, userId, text]);
    await db.execute('UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?', [postId]);
    res.status(201).json({ message: 'Comment added' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getComments = async (req, res) => {
  const postId = req.params.id;
  try {
    const [comments] = await db.execute(`
      SELECT c.*, u.username as author_name, u.profile_picture_url 
      FROM post_comments c 
      JOIN users u ON c.user_id = u.id 
      WHERE c.post_id = ? 
      ORDER BY c.created_at DESC
    `, [postId]);
    res.json(comments);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.deletePost = async (req, res) => {
  const postId = req.params.id;
  try {
    await db.execute('DELETE FROM posts WHERE id = ?', [postId]);
    res.json({ success: true, message: 'Post deleted' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.savePost = async (req, res) => {
  const { userId } = req.body;
  const postId = req.params.id;
  try {
    await db.execute(
      'INSERT INTO post_saves (post_id, user_id) VALUES (?, ?) ON CONFLICT (post_id, user_id) DO NOTHING',
      [postId, userId]
    );
    res.json({ message: 'Post saved' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.unsavePost = async (req, res) => {
  const { userId } = req.body;
  const postId = req.params.id;
  try {
    await db.execute('DELETE FROM post_saves WHERE post_id = ? AND user_id = ?', [postId, userId]);
    res.json({ message: 'Post unsaved' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getSavedPosts = async (req, res) => {
  const userId = req.params.userId;
  try {
    const [posts] = await db.execute(`
      SELECT p.* 
      FROM posts p
      JOIN post_saves s ON p.id = s.post_id
      WHERE s.user_id = ?
      ORDER BY s.created_at DESC
    `, [userId]);

    for (let post of posts) {
      const [tags] = await db.execute('SELECT tag_name FROM post_tags WHERE post_id = ?', [post.id]);
      post.tags = tags.map(t => t.tag_name);
    }

    res.json(posts);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.isPostSaved = async (req, res) => {
  const { userId, postId } = req.params;
  try {
    const [result] = await db.execute('SELECT 1 FROM post_saves WHERE post_id = ? AND user_id = ?', [postId, userId]);
    res.json({ isSaved: result.length > 0 });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.isPostLiked = async (req, res) => {
  const { id: postId, userId } = req.params;
  try {
    const [result] = await db.execute('SELECT 1 FROM post_likes WHERE post_id = ? AND user_id = ?', [postId, userId]);
    res.json({ isLiked: result.length > 0 });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

