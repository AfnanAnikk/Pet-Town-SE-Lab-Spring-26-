const db = require('../config/db');

exports.getAllVets = async (req, res) => {
  try {
    const { location, concern, species } = req.query;
    let query = 'SELECT DISTINCT v.* FROM vets v';
    let params = [];

    let requiredSkill = '';
    if (concern) {
      switch (concern) {
        case 'Vaccines & Preventive care': requiredSkill = 'Vaccinologist'; break;
        case 'Injury & Infection': requiredSkill = 'Surgeon'; break;
        case 'Cancer & Chronic Care': requiredSkill = 'Oncologist'; break;
        case 'Wellness & Checkups': requiredSkill = 'General Practitioner'; break;
        case 'Skin & Allergies': requiredSkill = 'Dermatologist'; break;
        case 'Dental Care': requiredSkill = 'Dentist'; break;
        default: requiredSkill = concern;
      }
    }

    if (requiredSkill) {
      query += ' JOIN vet_tags t ON v.id = t.vet_id';
    }

    if (species) {
      query += ' JOIN vet_species s ON v.id = s.vet_id';
    }

    let conditions = [];

    if (location) {
      conditions.push('LOWER(v.location) LIKE ?');
      params.push(`%${location.toLowerCase()}%`);
    }

    if (requiredSkill) {
      conditions.push('t.tag_name = ?');
      params.push(requiredSkill);
    }

    if (species) {
      conditions.push('s.species_name = ?');
      params.push(species);
    }

    if (conditions.length > 0) {
      query += ' WHERE ' + conditions.join(' AND ');
    }

    const [vets] = await db.execute(query, params);
    
    // Fetch tags and other details for each vet
    for (let vet of vets) {
      const [tags] = await db.execute('SELECT tag_name FROM vet_tags WHERE vet_id = ?', [vet.id]);
      const [slots] = await db.execute('SELECT slot_time FROM vet_slots WHERE vet_id = ?', [vet.id]);
      const [licences] = await db.execute('SELECT licence_name FROM vet_licences WHERE vet_id = ?', [vet.id]);
      const [species] = await db.execute('SELECT species_name FROM vet_species WHERE vet_id = ?', [vet.id]);
      const [areas] = await db.execute('SELECT area_name FROM vet_areas WHERE vet_id = ?', [vet.id]);
      const [reviews] = await db.execute('SELECT * FROM vet_reviews WHERE vet_id = ?', [vet.id]);

      vet.tags = tags.map(t => t.tag_name);
      vet.availableSlots = slots.map(s => s.slot_time);
      vet.licences = licences.map(l => l.licence_name);
      vet.speciesTreated = species.map(s => s.species_name);
      vet.areasOfInterest = areas.map(a => a.area_name);
      vet.reviews = reviews;
    }

    res.json(vets);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getVetById = async (req, res) => {
  const vetId = req.params.id;
  try {
    const [vets] = await db.execute('SELECT * FROM vets WHERE id = ?', [vetId]);
    
    if (vets.length === 0) {
      return res.status(404).json({ message: 'Vet not found' });
    }

    const vet = vets[0];

    // Fetch related data
    const [tags] = await db.execute('SELECT tag_name FROM vet_tags WHERE vet_id = ?', [vetId]);
    const [slots] = await db.execute('SELECT slot_time FROM vet_slots WHERE vet_id = ?', [vetId]);
    const [licences] = await db.execute('SELECT licence_name FROM vet_licences WHERE vet_id = ?', [vetId]);
    const [species] = await db.execute('SELECT species_name FROM vet_species WHERE vet_id = ?', [vetId]);
    const [areas] = await db.execute('SELECT area_name FROM vet_areas WHERE vet_id = ?', [vetId]);
    const [reviews] = await db.execute('SELECT * FROM vet_reviews WHERE vet_id = ?', [vetId]);

    vet.tags = tags.map(t => t.tag_name);
    vet.availableSlots = slots.map(s => s.slot_time);
    vet.licences = licences.map(l => l.licence_name);
    vet.speciesTreated = species.map(s => s.species_name);
    vet.areasOfInterest = areas.map(a => a.area_name);
    vet.reviews = reviews;

    res.json(vet);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.getVetByUserId = async (req, res) => {
  const userId = req.params.userId;
  try {
    const [vets] = await db.execute('SELECT * FROM vets WHERE user_id = ?', [userId]);
    
    if (vets.length === 0) {
      return res.status(404).json({ message: 'Vet profile not found' });
    }

    const vet = vets[0];
    const vetId = vet.id;

    // Fetch related data
    const [tags] = await db.execute('SELECT tag_name FROM vet_tags WHERE vet_id = ?', [vetId]);
    const [slots] = await db.execute('SELECT slot_time FROM vet_slots WHERE vet_id = ?', [vetId]);
    const [licences] = await db.execute('SELECT licence_name FROM vet_licences WHERE vet_id = ?', [vetId]);
    const [species] = await db.execute('SELECT species_name FROM vet_species WHERE vet_id = ?', [vetId]);
    const [areas] = await db.execute('SELECT area_name FROM vet_areas WHERE vet_id = ?', [vetId]);

    vet.tags = tags.map(t => t.tag_name);
    vet.availableSlots = slots.map(s => s.slot_time);
    vet.licences = licences.map(l => l.licence_name);
    vet.speciesTreated = species.map(s => s.species_name);
    vet.areasOfInterest = areas.map(a => a.area_name);

    res.json(vet);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', success: false });
  }
};

exports.verifyVet = async (req, res) => {
  const { userId, ownerName, nidNumber, tinNumber, tradeLicense, bvcRegistration, otherLicense } = req.body;

  try {
    const [vets] = await db.execute('SELECT id FROM vets WHERE user_id = ?', [userId]);
    if (vets.length === 0) {
      return res.status(404).json({ message: 'Vet not found for this user' });
    }
    const vetId = vets[0].id;

    await db.execute(
      'INSERT INTO vet_verifications (vet_id, owner_name, nid_number, tin_number, trade_license, bvc_registration, other_license) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [vetId, ownerName, nidNumber, tinNumber, tradeLicense, bvcRegistration, otherLicense || null]
    );

    // Also mark them as verified (for demo purposes)
    await db.execute('UPDATE vets SET is_verified = TRUE WHERE id = ?', [vetId]);

    res.status(201).json({ message: 'Verification details submitted successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
};

exports.updateVetProfile = async (req, res) => {
  const { 
    userId, name, degree, location, fee, about, 
    skills, species, areas, timeslots 
  } = req.body;

  try {
    // Check if vet exists for user, if not create one
    const [existingVets] = await db.execute('SELECT id FROM vets WHERE user_id = ?', [userId]);
    let vetId;
    
    if (existingVets.length === 0) {
      const [result] = await db.execute(
        'INSERT INTO vets (user_id, name, degree, location, price, profile_description) VALUES (?, ?, ?, ?, ?, ?)',
        [userId, name, degree, location, fee, about]
      );
      vetId = result.insertId;
    } else {
      vetId = existingVets[0].id;
      await db.execute(
        'UPDATE vets SET name = ?, degree = ?, location = ?, price = ?, profile_description = ? WHERE id = ?',
        [name, degree, location, fee, about, vetId]
      );
    }

    // Delete existing relations
    await db.execute('DELETE FROM vet_tags WHERE vet_id = ?', [vetId]);
    await db.execute('DELETE FROM vet_species WHERE vet_id = ?', [vetId]);
    await db.execute('DELETE FROM vet_areas WHERE vet_id = ?', [vetId]);
    await db.execute('DELETE FROM vet_slots WHERE vet_id = ?', [vetId]);

    // Insert new relations
    if (skills && skills.length > 0) {
      for (const skill of skills) {
        await db.execute('INSERT INTO vet_tags (vet_id, tag_name) VALUES (?, ?)', [vetId, skill]);
      }
    }
    
    if (species && species.length > 0) {
      for (const sp of species) {
        await db.execute('INSERT INTO vet_species (vet_id, species_name) VALUES (?, ?)', [vetId, sp]);
      }
    }

    if (areas && areas.length > 0) {
      for (const area of areas) {
        await db.execute('INSERT INTO vet_areas (vet_id, area_name) VALUES (?, ?)', [vetId, area]);
      }
    }

    if (timeslots && timeslots.length > 0) {
      for (const slot of timeslots) {
        await db.execute('INSERT INTO vet_slots (vet_id, slot_time) VALUES (?, ?)', [vetId, slot]);
      }
    }

    res.json({ message: 'Profile updated successfully', success: true });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error', success: false });
  }
};
