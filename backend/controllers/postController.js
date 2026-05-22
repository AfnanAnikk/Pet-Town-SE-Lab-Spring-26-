const db = require('../config/db');

exports.getAllPosts = async (req, res) => {
  try {
    const [posts] = await db.execute('SELECT * FROM posts');
    
    // Fetch tags for posts
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

exports.createPost = async (req, res) => {
  const { user_id, title, author_name, image_path, placeholder_color, placeholder_height, tags } = req.body;

  if (!user_id || !title || !image_path) {
    return res.status(400).json({ message: 'user_id, title, and image_path are required' });
  }

  try {
    const [result] = await db.execute(
      'INSERT INTO posts (user_id, title, author_name, image_path, placeholder_color, placeholder_height) VALUES (?, ?, ?, ?, ?, ?)',
      [user_id, title, author_name || '', image_path, placeholder_color || '', placeholder_height || 0.0]
    );

    const postId = result.insertId;

    if (tags && Array.isArray(tags)) {
      for (const tag of tags) {
        await db.execute('INSERT INTO post_tags (post_id, tag_name) VALUES (?, ?)', [postId, tag]);
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
    await db.execute('INSERT IGNORE INTO post_likes (post_id, user_id) VALUES (?, ?)', [postId, userId]);
    await db.execute('UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?', [postId]);
    res.json({ message: 'Post liked' });
  } catch (error) {
    if (error.code !== 'ER_DUP_ENTRY' && error.code !== '23505') {
      console.error(error);
      return res.status(500).json({ message: 'Server error' });
    }
    res.json({ message: 'Already liked' });
  }
};

exports.unlikePost = async (req, res) => {
  const { userId } = req.body;
  const postId = req.params.id;
  try {
    const [result] = await db.execute('DELETE FROM post_likes WHERE post_id = ? AND user_id = ?', [postId, userId]);
    if (result.affectedRows > 0 || result.rowCount > 0) {
      await db.execute('UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = ?', [postId]);
    }
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
      SELECT c.*, u.username as author_name 
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
