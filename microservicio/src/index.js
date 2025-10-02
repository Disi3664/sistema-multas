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
