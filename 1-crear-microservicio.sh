#!/bin/bash

################################################################################
# PARTE 1: Crear archivos del MICROSERVICIO
################################################################################

echo "════════════════════════════════════════════════════════════════"
echo "🐳 PARTE 1: Creando archivos del Microservicio"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar ubicación
if [ ! -d ".git" ]; then
    echo "❌ Error: Ejecutar desde carpeta sistema-multas"
    exit 1
fi

# 1. database.js
cat > microservicio/src/config/database.js << 'EOF'
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
EOF

echo "✓ database.js creado"

# 2. auth.js
cat > microservicio/src/middleware/auth.js << 'EOF'
function verificarApiKey(req, res, next) {
    const apiKey = req.headers['x-api-key'];
    
    if (!apiKey) {
        return res.status(401).json({ 
            error: 'API Key requerida',
            message: 'Debe proporcionar una API Key en el header X-API-Key'
        });
    }
    
    if (apiKey !== process.env.API_KEY) {
        return res.status(403).json({ 
            error: 'API Key inválida',
            message: 'La API Key proporcionada no es válida'
        });
    }
    
    next();
}

module.exports = { verificarApiKey };
EOF

echo "✓ auth.js creado"

# 3. conductor.js
cat > microservicio/src/routes/conductor.js << 'EOF'
const express = require('express');
const router = express.Router();
const db = require('../config/database');

router.get('/conductor', async (req, res) => {
    try {
        const { dni } = req.query;
        
        if (!dni) {
            return res.status(400).json({ 
                error: 'DNI requerido',
                message: 'Debe proporcionar el parámetro dni'
            });
        }

        const [rows] = await db.query(
            `SELECT 
                dni, nombre, apellidos, email, telefono,
                direccion, codigo_postal, ciudad, provincia
            FROM conductores 
            WHERE dni = ? AND activo = 1`,
            [dni]
        );

        if (rows.length === 0) {
            return res.status(404).json({ 
                error: 'Conductor no encontrado',
                message: \`No se encontró conductor con DNI \${dni}\`
            });
        }

        res.json({
            success: true,
            data: rows[0]
        });

    } catch (error) {
        console.error('Error consultando conductor:', error);
        res.status(500).json({ 
            error: 'Error interno',
            message: 'Error al consultar la base de datos'
        });
    }
});

module.exports = router;
EOF

echo "✓ conductor.js creado"

# 4. index.js
cat > microservicio/src/index.js << 'EOF'
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const conductorRoutes = require('./routes/conductor');
const { verificarApiKey } = require('./middleware/auth');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok', 
        service: 'API Empresa - Consulta Conductores',
        timestamp: new Date().toISOString(),
        version: '1.0.0'
    });
});

app.use('/api', verificarApiKey, conductorRoutes);

app.use((req, res) => {
    res.status(404).json({ 
        error: 'Ruta no encontrada',
        message: \`La ruta \${req.path} no existe\`
    });
});

app.use((err, req, res, next) => {
    console.error('Error:', err.stack);
    res.status(500).json({ 
        error: 'Error interno del servidor',
        message: process.env.NODE_ENV === 'development' ? err.message : 'Ha ocurrido un error'
    });
});

app.listen(PORT, () => {
    console.log('═══════════════════════════════════════');
    console.log('🚀 Microservicio API Empresa iniciado');
    console.log(\`📡 Puerto: \${PORT}\`);
    console.log(\`🌍 Entorno: \${process.env.NODE_ENV || 'development'}\`);
    console.log(\`🔗 Health: http://localhost:\${PORT}/health\`);
    console.log('═══════════════════════════════════════');
});

process.on('SIGTERM', () => {
    console.log('SIGTERM recibido. Cerrando servidor...');
    process.exit(0);
});

process.on('SIGINT', () => {
    console.log('SIGINT recibido. Cerrando servidor...');
    process.exit(0);
});
EOF

echo "✓ index.js creado"

# 5. Dockerfile
cat > microservicio/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY src/ ./src/

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

RUN chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3001/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

CMD ["node", "src/index.js"]
EOF

echo "✓ Dockerfile creado"

# 6. docker-compose.yml
cat > microservicio/docker-compose.yml << 'EOF'
version: '3.8'

services:
  api-empresa:
    build: .
    container_name: api-empresa-multas
    restart: unless-stopped
    ports:
      - "${PORT:-3001}:3001"
    environment:
      - NODE_ENV=${NODE_ENV:-production}
      - PORT=3001
      - DB_HOST=${DB_HOST}
      - DB_PORT=${DB_PORT:-3306}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
      - API_KEY=${API_KEY}
    networks:
      - empresa-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3001/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  empresa-network:
    driver: bridge
EOF

echo "✓ docker-compose.yml creado"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ PARTE 1 COMPLETADA - Microservicio creado (6 archivos)"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Archivos creados:"
echo "  ✓ microservicio/src/config/database.js"
echo "  ✓ microservicio/src/middleware/auth.js"
echo "  ✓ microservicio/src/routes/conductor.js"
echo "  ✓ microservicio/src/index.js"
echo "  ✓ microservicio/Dockerfile"
echo "  ✓ microservicio/docker-compose.yml"
echo ""
echo "Siguiente: Ejecuta ./2-crear-backend.sh"
