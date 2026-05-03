const db = require('./config/db');

async function seed() {
  try {
    console.log('Seeding database...');
    
    // Clear existing data (optional, but good for idempotency)
    // Be careful with this in a real production environment!
    await db.execute('SET FOREIGN_KEY_CHECKS = 0');
    await db.execute('TRUNCATE TABLE post_tags');
    await db.execute('TRUNCATE TABLE posts');
    await db.execute('TRUNCATE TABLE vet_reviews');
    await db.execute('TRUNCATE TABLE vet_areas');
    await db.execute('TRUNCATE TABLE vet_species');
    await db.execute('TRUNCATE TABLE vet_licences');
    await db.execute('TRUNCATE TABLE vet_slots');
    await db.execute('TRUNCATE TABLE vet_tags');
    await db.execute('TRUNCATE TABLE vets');
    await db.execute('TRUNCATE TABLE users');
    await db.execute('SET FOREIGN_KEY_CHECKS = 1');

    // Create dummy users first
    const [userResult] = await db.execute('INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)', ['admin@pettown.com', 'hashedpassword', 'user']);
    const userId = userResult.insertId;

    const [vetUser1] = await db.execute('INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)', ['vet1@pettown.com', 'hashedpassword', 'service_provider']);
    const vetUserId1 = vetUser1.insertId;

    const [vetUser2] = await db.execute('INSERT INTO users (email, password_hash, role) VALUES (?, ?, ?)', ['vet2@pettown.com', 'hashedpassword', 'service_provider']);
    const vetUserId2 = vetUser2.insertId;

    // Dummy Vets
    const vetsData = [
      {
        user_id: vetUserId1,
        name: 'Dr. Bahar Hossain',
        degree: 'Veterinarian, DMC',
        is_verified: true,
        rating: 5.0,
        review_count: 3,
        price: 9035,
        profile_description: 'I\'m a licensed veterinarian with over a decade of clinical experience and a lifelong love for feline medicine. My journey began in 2010 as a volunteer in Dhaka clinics, and I graduated as a vet...',
        tags: ['Immunologist', 'Vaccinologist', 'Biosecurity Veterinarian'],
        slots: ['Today at 9:00 AM', 'Today at 10:00 AM', 'Today at 11:30 AM', 'Today at 1:00 PM', 'Today at 2:00 PM', 'Today at 3:30 PM', 'Today at 4:00 PM', 'Today at 5:00 PM', 'Today at 6:00 PM'],
        licences: ['DVM', 'MSc', 'PhD (Vet Science)', 'BVC Registration'],
        species: ['Dog', 'Cat', 'Bird'],
        areas: ['Emergency', 'Dermatology', 'Nutrition'],
        reviews: [
          { author_name: 'Afnan Mehmud', author_initial: 'A', review_date: 'December, 2025', text: 'Very good but do not find any prescription online.' },
          { author_name: 'Juboraz Afnan', author_initial: 'J', review_date: 'October, 2025', text: 'Not bad.' },
          { author_name: 'Not Afnan', author_initial: 'N', review_date: 'September, 2025', text: 'I trust Dr. Bahar Hossain with my dog\'s life.' }
        ]
      },
      {
        user_id: vetUserId2,
        name: 'Dr. SR Begum',
        degree: 'Veterinarian, GAU',
        is_verified: true,
        rating: 4.9,
        review_count: 21,
        price: 9035,
        profile_description: 'Passionate about animal pathology and disease prevention. Dedicated to providing the best care for your beloved companions.',
        tags: ['Epidemiologist', 'Pathologist', 'Microbiologist'],
        slots: ['Today at 10:00 AM', 'Today at 11:00 AM', 'Today at 1:00 PM', 'Today at 2:00 PM', 'Today at 3:00 PM', 'Today at 4:00 PM', 'Today at 5:00 PM'],
        licences: ['DVM', 'PhD (Pathology)'],
        species: ['Dog', 'Cat'],
        areas: ['Pathology', 'Infectious Diseases', 'Surgery'],
        reviews: [
          { author_name: 'Sarah K.', author_initial: 'S', review_date: 'January, 2026', text: 'She is incredibly thorough and kind.' }
        ]
      }
    ];

    for (const v of vetsData) {
      const [res] = await db.execute(
        'INSERT INTO vets (user_id, name, degree, is_verified, rating, review_count, price, profile_description) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [v.user_id, v.name, v.degree, v.is_verified, v.rating, v.review_count, v.price, v.profile_description]
      );
      const vetId = res.insertId;

      for (const t of v.tags) await db.execute('INSERT INTO vet_tags (vet_id, tag_name) VALUES (?, ?)', [vetId, t]);
      for (const s of v.slots) await db.execute('INSERT INTO vet_slots (vet_id, slot_time) VALUES (?, ?)', [vetId, s]);
      for (const l of v.licences) await db.execute('INSERT INTO vet_licences (vet_id, licence_name) VALUES (?, ?)', [vetId, l]);
      for (const s of v.species) await db.execute('INSERT INTO vet_species (vet_id, species_name) VALUES (?, ?)', [vetId, s]);
      for (const a of v.areas) await db.execute('INSERT INTO vet_areas (vet_id, area_name) VALUES (?, ?)', [vetId, a]);
      for (const r of v.reviews) await db.execute(
        'INSERT INTO vet_reviews (vet_id, author_name, author_initial, review_date, text) VALUES (?, ?, ?, ?, ?)',
        [vetId, r.author_name, r.author_initial, r.review_date, r.text]
      );
    }

    // Dummy Posts
    const colors = ['#CFD8DC', '#D7CCC8', '#B2DFDB', '#FFE0B2', '#E1BEE7', '#FFCCBC'];
    const heights = [180.0, 220.0, 260.0, 300.0, 150.0];
    const imageOrder = [3, 8, 1, 10, 5, 2, 7, 4, 9, 6];

    for (let i = 0; i < 20; i++) {
      const imageNumber = imageOrder[i % imageOrder.length];
      const color = colors[i % colors.length];
      const height = heights[i % heights.length];

      const [postRes] = await db.execute(
        'INSERT INTO posts (user_id, title, author_name, likes_count, comments_count, image_path, placeholder_color, placeholder_height) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [userId, `Pookie cat ${i}`, 'Monica Teller', 138 + i * 2, 6 + i, `assets/images/p${imageNumber}.png`, color, height]
      );
      const postId = postRes.insertId;

      const tags = ['#CatLover', '#SmallCat', '#CuteCat'];
      for (const t of tags) await db.execute('INSERT INTO post_tags (post_id, tag_name) VALUES (?, ?)', [postId, t]);
    }

    console.log('Seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  }
}

seed();
