const { Pool } = require('pg');

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
});

pool.connect()
    .then(client => {
        console.log('✓ Conexión a PostgreSQL establecida');
        client.release();
    })
    .catch(err => {
        console.error('✗ Error conectando a PostgreSQL:', err.message);
        process.exit(1);
    });

pool.on('error', (err, client) => {
    console.error('Error inesperado en el pool de PostgreSQL:', err);
});

module.exports = pool;
