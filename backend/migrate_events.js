const db = require('./config/db');

const sql = `
CREATE TABLE IF NOT EXISTS events (
    id                    SERIAL PRIMARY KEY,
    user_id               INT NOT NULL,
    title                 VARCHAR(255) NOT NULL,
    description           TEXT,
    cover_image_url       VARCHAR(255),
    category              VARCHAR(100),
    pet_type              VARCHAR(100) DEFAULT 'All',
    start_datetime        TIMESTAMP NOT NULL,
    end_datetime          TIMESTAMP,
    location              VARCHAR(255),
    latitude              DECIMAL(9,6),
    longitude             DECIMAL(9,6),
    max_participants      INT DEFAULT 0,
    contact_info          VARCHAR(255),
    requires_registration BOOLEAN DEFAULT FALSE,
    visibility            VARCHAR(20) DEFAULT 'public' CHECK (visibility IN ('public','private','invite_only')),
    status                VARCHAR(20) DEFAULT 'upcoming' CHECK (status IN ('draft','upcoming','ongoing','completed','cancelled')),
    interested_count      INT DEFAULT 0,
    going_count           INT DEFAULT 0,
    created_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_participants (
    id         SERIAL PRIMARY KEY,
    event_id   INT NOT NULL,
    user_id    INT NOT NULL,
    status     VARCHAR(20) DEFAULT 'interested' CHECK (status IN ('interested','going','cancelled')),
    approved   BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_saves (
    event_id   INT NOT NULL,
    user_id    INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, user_id),
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_comments (
    id         SERIAL PRIMARY KEY,
    event_id   INT NOT NULL,
    user_id    INT NOT NULL,
    parent_id  INT DEFAULT NULL,
    text       TEXT NOT NULL,
    is_pinned  BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id)  REFERENCES events(id)         ON DELETE CASCADE,
    FOREIGN KEY (user_id)   REFERENCES users(id)          ON DELETE CASCADE,
    FOREIGN KEY (parent_id) REFERENCES event_comments(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_comment_reactions (
    comment_id INT NOT NULL,
    user_id    INT NOT NULL,
    reaction   VARCHAR(20) DEFAULT 'like',
    PRIMARY KEY (comment_id, user_id),
    FOREIGN KEY (comment_id) REFERENCES event_comments(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)    REFERENCES users(id)          ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_gallery (
    id          SERIAL PRIMARY KEY,
    event_id    INT NOT NULL,
    image_url   VARCHAR(255) NOT NULL,
    uploaded_by INT NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id)    REFERENCES events(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES users(id)  ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS event_invitations (
    id         SERIAL PRIMARY KEY,
    event_id   INT NOT NULL,
    inviter_id INT NOT NULL,
    invitee_id INT NOT NULL,
    status     VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (event_id, invitee_id),
    FOREIGN KEY (event_id)   REFERENCES events(id) ON DELETE CASCADE,
    FOREIGN KEY (inviter_id) REFERENCES users(id)  ON DELETE CASCADE,
    FOREIGN KEY (invitee_id) REFERENCES users(id)  ON DELETE CASCADE
);
`;

async function runMigration() {
  try {
    console.log('Starting Pet Events DB Migrations...');
    await db.pool.query(sql);
    console.log('Pet Events tables created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

runMigration();
