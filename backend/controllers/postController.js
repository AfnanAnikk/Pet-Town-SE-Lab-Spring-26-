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
    res.status(500).json({ message: 'Server error' });
  }
};
