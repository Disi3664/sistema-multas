const express = require('express');
const router = express.Router();
const db = require('../config/database');
const microservicioClient = require('../services/microservicioClient');

// GET /api/empresas - Listar todas las empresas
router.get('/', async (req, res) => {
    try {
        const { activo } = req.query;
        
        let query = 'SELECT * FROM empresas';
        const params = [];
        
        if (activo !== undefined) {
            query += ' WHERE activo = $1';
            params.push(activo === 'true');
        }
        
        query += ' ORDER BY nombre';

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Error en GET /empresas:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// GET /api/empresas/:id - Obtener detalle de empresa
router.get('/:id', async (req, res) => {
    try {
        const result = await db.query(
            'SELECT * FROM empresas WHERE id = $1',
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Empresa no encontrada'
            });
        }

        res.json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Error en GET /empresas/:id:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// POST /api/empresas - Crear nueva empresa
router.post('/', async (req, res) => {
    try {
        const {
            nombre,
            cif,
            email,
            telefono,
            direccion,
            api_url,
            api_key,
            servicio_recurso,
            precio_gestion,
            precio_recurso
        } = req.body;

        if (!nombre || !cif || !email) {
            return res.status(400).json({
                success: false,
                message: 'Nombre, CIF y email son obligatorios'
            });
        }

        const result = await db.query(
            `INSERT INTO empresas (
                nombre, cif, email, telefono, direccion,
                api_url, api_key, servicio_recurso,
                precio_gestion, precio_recurso
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
            RETURNING *`,
            [
                nombre, cif, email, telefono, direccion,
                api_url, api_key, servicio_recurso || false,
                precio_gestion || 15.00, precio_recurso || 150.00
            ]
        );

        res.status(201).json({
            success: true,
            data: result.rows[0],
            message: 'Empresa creada correctamente'
        });
    } catch (error) {
        console.error('Error en POST /empresas:', error);
        
        if (error.code === '23505') { // Duplicate key
            return res.status(409).json({
                success: false,
                message: 'Ya existe una empresa con ese CIF'
            });
        }

        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// PUT /api/empresas/:id - Actualizar empresa
router.put('/:id', async (req, res) => {
    try {
        const {
            nombre,
            email,
            telefono,
            direccion,
            api_url,
            api_key,
            servicio_recurso,
            precio_gestion,
            precio_recurso,
            activo
        } = req.body;

        const result = await db.query(
            `UPDATE empresas 
             SET nombre = COALESCE($1, nombre),
                 email = COALESCE($2, email),
                 telefono = COALESCE($3, telefono),
                 direccion = COALESCE($4, direccion),
                 api_url = COALESCE($5, api_url),
                 api_key = COALESCE($6, api_key),
                 servicio_recurso = COALESCE($7, servicio_recurso),
                 precio_gestion = COALESCE($8, precio_gestion),
                 precio_recurso = COALESCE($9, precio_recurso),
                 activo = COALESCE($10, activo),
                 updated_at = NOW()
             WHERE id = $11
             RETURNING *`,
            [
                nombre, email, telefono, direccion,
                api_url, api_key, servicio_recurso,
                precio_gestion, precio_recurso, activo,
                req.params.id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Empresa no encontrada'
            });
        }

        res.json({
            success: true,
            data: result.rows[0],
            message: 'Empresa actualizada correctamente'
        });
    } catch (error) {
        console.error('Error en PUT /empresas/:id:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// POST /api/empresas/:id/verificar-conexion - Verificar microservicio
router.post('/:id/verificar-conexion', async (req, res) => {
    try {
        const resultado = await microservicioClient.verificarConexion(req.params.id);
        res.json(resultado);
    } catch (error) {
        console.error('Error verificando conexión:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

module.exports = router;
