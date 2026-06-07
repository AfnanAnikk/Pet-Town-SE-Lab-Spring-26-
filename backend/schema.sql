-- PostgreSQL Schema
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255),
    display_name VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50),
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    service_type VARCHAR(255),
    profile_picture_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vets (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    service_type VARCHAR(255),
    degree VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE,
    rating FLOAT DEFAULT 0.0,
    review_count INT DEFAULT 0,
    price INT DEFAULT 0,
    location VARCHAR(255),
    profile_description TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_tags (
    id SERIAL PRIMARY KEY,
    vet_id INT NOT NULL,
    tag_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_slots (
    id SERIAL PRIMARY KEY,
    vet_id INT NOT NULL,
    slot_time VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_licences (
    id SERIAL PRIMARY KEY,
    vet_id INT NOT NULL,
    licence_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_species (
    id SERIAL PRIMARY KEY,
    vet_id INT NOT NULL,
    species_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_areas (
    id SERIAL PRIMARY KEY,
    vet_id INT NOT NULL,
    area_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_reviews (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    vet_id INT NOT NULL,
    user_id INT NOT NULL,
    rating FLOAT NOT NULL,
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS posts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    author_name VARCHAR(255) NOT NULL,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    image_path VARCHAR(255) NOT NULL,
    placeholder_color VARCHAR(50),
    placeholder_height FLOAT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS post_tags (
    id SERIAL PRIMARY KEY,
    post_id INT NOT NULL,
    tag_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS post_likes (
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS post_comments (
    id SERIAL PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_verifications (
    id SERIAL PRIMARY KEY,
    vet_id INT NOT NULL,
    owner_name VARCHAR(255),
    nid_front_url VARCHAR(255),
    nid_back_url VARCHAR(255),
    tin_url VARCHAR(255),
    trade_url VARCHAR(255),
    bvc_url VARCHAR(255),
    other_url VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    vet_id INT NOT NULL,
    pet_name VARCHAR(255),
    pet_species VARCHAR(255),
    pet_breed VARCHAR(255),
    pet_sex VARCHAR(50),
    pet_age VARCHAR(50),
    concern VARCHAR(255),
    reason TEXT,
    payment_method VARCHAR(100),
    slot_time VARCHAR(255),
    booking_date VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    voucher_code VARCHAR(50),
    discount_amount INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS conversations (
    id SERIAL PRIMARY KEY,
    user1_id INT NOT NULL,
    user2_id INT NOT NULL,
    last_message_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user1_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (user2_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (user1_id, user2_id)
);

CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    conversation_id INT NOT NULL,
    sender_id INT NOT NULL,
    text TEXT NOT NULL,
    image_url TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS stores (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) DEFAULT 'General',
    banner_color VARCHAR(50) DEFAULT '#3293B3',
    banner_url VARCHAR(255),
    contact_info VARCHAR(100),
    location VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE,
    rating FLOAT DEFAULT 0.0,
    review_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    store_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    price NUMERIC(10, 2) NOT NULL,
    original_price NUMERIC(10, 2),
    quantity INT DEFAULT 0,
    discount_percent INT DEFAULT 0,
    image_path VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS coupons (
    id SERIAL PRIMARY KEY,
    store_id INT NOT NULL,
    code VARCHAR(50) NOT NULL,
    discount_percent INT NOT NULL,
    min_order_amount NUMERIC(10, 2) DEFAULT 0,
    max_uses INT DEFAULT 100,
    used_count INT DEFAULT 0,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_vouchers (
    id SERIAL PRIMARY KEY,
    vet_id INT NOT NULL,
    code VARCHAR(50) NOT NULL,
    discount_percent INT NOT NULL,
    max_uses INT DEFAULT 100,
    used_count INT DEFAULT 0,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    store_id INT NOT NULL,
    total_price NUMERIC(10, 2) NOT NULL,
    coupon_code VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    delivery_address TEXT,
    payment_method VARCHAR(50),
    tip_amount NUMERIC(10, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    price NUMERIC(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS store_verifications (
    id SERIAL PRIMARY KEY,
    store_id INT NOT NULL,
    owner_name VARCHAR(255),
    nid_number VARCHAR(255),
    trade_license VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (store_id) REFERENCES stores(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS adoptions (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    pet_name VARCHAR(255) NOT NULL,
    pet_type VARCHAR(100),
    pet_breed VARCHAR(255),
    pet_age VARCHAR(50),
    pet_traits VARCHAR(255),
    pet_gender VARCHAR(50),
    pet_food_habit TEXT,
    owner_name VARCHAR(255),
    owner_contact VARCHAR(100),
    description TEXT,
    image_url VARCHAR(255),
    status VARCHAR(50) DEFAULT 'available',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS adoption_requests (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    adoption_id INT NOT NULL,
    requester_name VARCHAR(255),
    requester_phone VARCHAR(100),
    requester_address TEXT,
    pickup_date DATE,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (adoption_id) REFERENCES adoptions(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS shelters (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255),
    total_seat INT DEFAULT 0,
    occupied_seat INT DEFAULT 0,
    vacant_seat INT DEFAULT 0,
    fb_url VARCHAR(255),
    website_url VARCHAR(255),
    logo_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS shelter_bookings (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    shelter_id INT NOT NULL,
    pet_type VARCHAR(100),
    pet_name VARCHAR(255),
    from_date VARCHAR(100),
    to_date VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (shelter_id) REFERENCES shelters(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS post_saves (
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, user_id),
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Pet Salon Tables
CREATE TABLE IF NOT EXISTS salons (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    owner_name VARCHAR(255),
    profile_picture_url VARCHAR(255),
    location VARCHAR(255),
    price INT DEFAULT 0,
    rating FLOAT DEFAULT 0.0,
    review_count INT DEFAULT 0,
    total_bookings INT DEFAULT 0,
    profile_description TEXT,
    is_verified BOOLEAN DEFAULT false,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS salon_tags (
    id SERIAL PRIMARY KEY,
    salon_id INT NOT NULL,
    tag VARCHAR(100) NOT NULL,
    FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS salon_slots (
    id SERIAL PRIMARY KEY,
    salon_id INT NOT NULL,
    slot_time VARCHAR(255) NOT NULL,
    FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS follows (
    id SERIAL PRIMARY KEY,
    follower_id INT NOT NULL,
    following_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (follower_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (following_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE (follower_id, following_id)
);

CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    type VARCHAR(50) NOT NULL,
    reference_id INT,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS salon_reviews (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    salon_id INT NOT NULL,
    user_id INT NOT NULL,
    rating FLOAT NOT NULL,
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES salon_bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS salon_bookings (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    salon_id INT NOT NULL,
    pet_name VARCHAR(255),
    pet_species VARCHAR(255),
    pet_breed VARCHAR(255),
    pet_sex VARCHAR(50),
    pet_age VARCHAR(50),
    concern VARCHAR(255),
    reason TEXT,
    payment_method VARCHAR(100),
    slot_time VARCHAR(255),
    booking_date VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    voucher_code VARCHAR(50),
    discount_amount INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS salon_vouchers (
    id SERIAL PRIMARY KEY,
    salon_id INT NOT NULL,
    code VARCHAR(50) NOT NULL,
    discount_percent INT NOT NULL,
    max_uses INT DEFAULT 1,
    used_count INT DEFAULT 0,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS salon_verifications (
    id SERIAL PRIMARY KEY,
    salon_id INT NOT NULL,
    owner_name VARCHAR(255),
    nid_front_url VARCHAR(255),
    nid_back_url VARCHAR(255),
    tin_url VARCHAR(255),
    trade_url VARCHAR(255),
    other_url VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE CASCADE
);

-- ══════════════════════════════════════════════════════════════════════════════
--  PET EVENTS FEATURE
-- ══════════════════════════════════════════════════════════════════════════════

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
    visibility            VARCHAR(20) DEFAULT 'public'
                              CHECK (visibility IN ('public','private','invite_only')),
    status                VARCHAR(20) DEFAULT 'upcoming'
                              CHECK (status IN ('draft','upcoming','ongoing','completed','cancelled')),
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
    status     VARCHAR(20) DEFAULT 'interested'
                   CHECK (status IN ('interested','going','cancelled')),
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
    status     VARCHAR(20) DEFAULT 'pending'
                   CHECK (status IN ('pending','accepted','declined')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (event_id, invitee_id),
    FOREIGN KEY (event_id)   REFERENCES events(id) ON DELETE CASCADE,
    FOREIGN KEY (inviter_id) REFERENCES users(id)  ON DELETE CASCADE,
    FOREIGN KEY (invitee_id) REFERENCES users(id)  ON DELETE CASCADE
);

