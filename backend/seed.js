const fs = require('fs');
const path = require('path');
const db = require('./config/db');

async function seed() {
  try {
    console.log('Initializing database schema...');
    
    // Read and execute the schema.sql file directly via pg pool
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');
    
    // pg's pool.query can execute multiple statements separated by semicolons
    await db.pool.query(schemaSql);
    console.log('Schema executed successfully.');

    console.log('Seeding database...');
    
    // Clear existing data (optional, but good for idempotency)
    // Be careful with this in a real production environment!
    await db.execute('TRUNCATE TABLE post_tags CASCADE');
    await db.execute('TRUNCATE TABLE posts CASCADE');
    await db.execute('TRUNCATE TABLE vet_reviews CASCADE');
    await db.execute('TRUNCATE TABLE vet_areas CASCADE');
    await db.execute('TRUNCATE TABLE vet_species CASCADE');
    await db.execute('TRUNCATE TABLE vet_licences CASCADE');
    await db.execute('TRUNCATE TABLE vet_slots CASCADE');
    await db.execute('TRUNCATE TABLE vet_tags CASCADE');
    await db.execute('TRUNCATE TABLE vets CASCADE');
    await db.execute('TRUNCATE TABLE users CASCADE');

    // Create admin user
    await db.execute('INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)', ['admin@pettown.com', 'hashedpassword', 'user']);

    console.log('Seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  }
}

seed();
