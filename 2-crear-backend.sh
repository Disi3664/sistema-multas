#!/bin/bash

################################################################################
# PARTE 2: Crear archivos del BACKEND
################################################################################

echo "════════════════════════════════════════════════════════════════"
echo "💻 PARTE 2: Creando archivos del Backend"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar ubicación
if [ ! -d ".git" ]; then
    echo "❌ Error: Ejecutar desde carpeta sistema-multas"
    exit 1
fi

# 1. Config - database.js
cat > backend/src/config/database.js << 'EOF'
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
EOF

echo "✓ backend/src/config/database.js"

# 2. Config - redis.js
cat > backend/src/config/redis.js << 'EOF'
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
EOF

echo "✓ backend/src/config/redis.js"

# 3. Actualizar package.json backend para incluir axios
cd backend
if command -v npm &> /dev/null; then
    echo "→ Instalando axios en backend..."
    npm install axios --save 2>/dev/null
    echo "✓ axios instalado"
fi
cd ..

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ PARTE 2 COMPLETADA - Backend config creado"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "IMPORTANTE: Los archivos de services y routes son muy largos."
echo "Por favor, copia manualmente estos 5 archivos desde los artefactos:"
echo ""
echo "  → backend/src/services/microservicioClient.js"
echo "     (Artefacto: backend_microservicio_client)"
echo ""
echo "  → backend/src/services/multasService.js"
echo "     (Artefacto: backend_multas_service)"
echo ""
echo "  → backend/src/routes/multas.js"
echo "     (Artefacto: backend_multas_routes)"
echo ""
echo "  → backend/src/routes/empresas.js"
echo "     (Artefacto: backend_empresas_routes)"
echo ""
echo "  → backend/src/routes/facturas.js"
echo "     (Artefacto: backend_facturas_routes)"
echo ""
echo "Una vez copiados, ejecuta: ./3-crear-database-scripts.sh"
