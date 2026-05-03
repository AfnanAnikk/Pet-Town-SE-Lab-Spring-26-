const mysql = require('mysql2/promise');

async function test() {
  const db = await mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'pet_town_db'
  });

  const [rows] = await db.execute('SELECT * FROM vets');
  console.log('VETS in DB:', rows);
  db.end();
}
test();
