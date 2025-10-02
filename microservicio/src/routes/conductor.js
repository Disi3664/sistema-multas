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
