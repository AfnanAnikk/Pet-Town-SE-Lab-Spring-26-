const db = require('./config/db');

async function migrate() {
  try {
    await db.pool.query(`
      CREATE TABLE IF NOT EXISTS post_saves (
        post_id INT NOT NULL,
        user_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    console.log('post_saves table ready!');

    await db.pool.query(`
      CREATE TABLE IF NOT EXISTS post_likes (
        post_id INT NOT NULL,
        user_id INT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (post_id, user_id),
        FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    console.log('post_likes table ready!');

    const r = await db.pool.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name"
    );
    console.log('All tables:', r.rows.map(t => t.table_name).join(', '));
    process.exit(0);
  } catch(e) {
    console.error('Migration error:', e.message);
    process.exit(1);
  }
}

migrate();
