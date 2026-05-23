const mysql = require('c:\\Users\\MD. SHAFIUL BARI\\Desktop\\p\\backend\\node_modules\\mysql2/promise');

async function probe() {
  try {
    console.log('Probing MySQL with root/empty...');
    const db = await mysql.createConnection({
      host: 'localhost',
      user: 'root',
      password: '',
    });
    console.log('>>> SUCCESS! Connected to MySQL!');
    const [rows] = await db.execute('SHOW DATABASES');
    console.log('Databases:', rows);
    await db.end();
    process.exit(0);
  } catch (err) {
    console.log('Failed for MySQL root/empty:', err.message);
    process.exit(1);
  }
}

probe();
