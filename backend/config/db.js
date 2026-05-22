const { Pool } = require('pg');
const dotenv = require('dotenv');

dotenv.config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/pet_town_db',
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

// Wrapper to mimic mysql2's db.execute behavior so controllers don't need to be fully rewritten
const execute = async (query, params = []) => {
  // Convert ? to $1, $2, etc. for PostgreSQL
  let i = 1;
  const pgQuery = query.replace(/\?/g, () => `$${i++}`);
  
  const isInsert = pgQuery.trim().toUpperCase().startsWith('INSERT');
  let finalQuery = pgQuery;
  
  // PostgreSQL needs RETURNING id to get the inserted row's id
  if (isInsert && !finalQuery.toUpperCase().includes('RETURNING')) {
    finalQuery += ' RETURNING id';
  }

  const result = await pool.query(finalQuery, params);
  
  if (isInsert && result.rows.length > 0 && result.rows[0].id) {
    result.insertId = result.rows[0].id;
    return [result, result.fields];
  }
  
  return [result.rows, result.fields];
};

module.exports = {
  execute,
  pool
};
