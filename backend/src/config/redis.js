const redis = require('redis');

const client = redis.createClient({
    socket: {
        host: process.env.REDIS_HOST || 'localhost',
        port: process.env.REDIS_PORT || 6379
    },
    password: process.env.REDIS_PASSWORD || undefined
});

client.on('connect', () => {
    console.log('✓ Conexión a Redis establecida');
});

client.on('error', (err) => {
    console.error('✗ Error en Redis:', err.message);
});

client.connect().catch(err => {
    console.error('Error al conectar con Redis:', err);
});

const cache = {
    async get(key) {
        try {
            const data = await client.get(key);
            return data ? JSON.parse(data) : null;
        } catch (error) {
            console.error('Error obteniendo cache:', error);
            return null;
        }
    },

    async set(key, value, ttl = 3600) {
        try {
            await client.setEx(key, ttl, JSON.stringify(value));
            return true;
        } catch (error) {
            console.error('Error guardando cache:', error);
            return false;
        }
    },

    async del(key) {
        try {
            await client.del(key);
            return true;
        } catch (error) {
            console.error('Error eliminando cache:', error);
            return false;
        }
    },

    async clearPattern(pattern) {
        try {
            const keys = await client.keys(pattern);
            if (keys.length > 0) {
                await client.del(keys);
            }
            return true;
        } catch (error) {
            console.error('Error limpiando cache:', error);
            return false;
        }
    }
};

module.exports = { client, cache };
