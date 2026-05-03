CREATE DATABASE IF NOT EXISTS pet_town_db;
USE pet_town_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50),
    role ENUM('user', 'service_provider') NOT NULL DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS vets (
    id INT AUTO_INCREMENT PRIMARY KEY,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
    vet_id INT NOT NULL,
    tag_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_slots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vet_id INT NOT NULL,
    slot_time VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_licences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vet_id INT NOT NULL,
    licence_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_species (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vet_id INT NOT NULL,
    species_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_areas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vet_id INT NOT NULL,
    area_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vet_id INT NOT NULL,
    author_name VARCHAR(255) NOT NULL,
    author_initial CHAR(1) NOT NULL,
    review_date VARCHAR(255) NOT NULL,
    text TEXT NOT NULL,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    author_name VARCHAR(255) NOT NULL,
    likes_count INT DEFAULT 0,
    comments_count INT DEFAULT 0,
    image_path VARCHAR(255) NOT NULL,
    placeholder_color VARCHAR(50),
    placeholder_height FLOAT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS post_tags (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    tag_name VARCHAR(255) NOT NULL,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vet_verifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vet_id INT NOT NULL,
    owner_name VARCHAR(255),
    nid_number VARCHAR(255),
    tin_number VARCHAR(255),
    trade_license VARCHAR(255),
    bvc_registration VARCHAR(255),
    other_license VARCHAR(255),
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
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
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (vet_id) REFERENCES vets(id) ON DELETE CASCADE
);
