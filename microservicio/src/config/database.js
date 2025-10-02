const mysql = require('mysql2/promise');

const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
});

pool.getConnection()
    .then(connection => {
        console.log('✓ Conexión a base de datos establecida');
        connection.release();
    })
    .catch(err => {
        console.error('✗ Error conectando a la base de datos:', err.message);
        process.exit(1);
    });

module.exports = pool;
