const express = require('express');
const router = express.Router();
const db = require('../config/database');

// GET /api/facturas - Listar facturas
router.get('/', async (req, res) => {
    try {
        const { empresa_id, estado, fecha_desde, fecha_hasta } = req.query;
        
        const params = [];
        const condiciones = [];
        let paramIndex = 1;

        if (empresa_id) {
            condiciones.push(`f.empresa_id = $${paramIndex++}`);
            params.push(empresa_id);
        }

        if (estado) {
            condiciones.push(`f.estado = $${paramIndex++}`);
            params.push(estado);
        }

        if (fecha_desde) {
            condiciones.push(`f.fecha_emision >= $${paramIndex++}`);
            params.push(fecha_desde);
        }

        if (fecha_hasta) {
            condiciones.push(`f.fecha_emision <= $${paramIndex++}`);
            params.push(fecha_hasta);
        }

        const whereClause = condiciones.length > 0 
            ? 'WHERE ' + condiciones.join(' AND ')
            : '';

        const query = `
            SELECT f.*, e.nombre as empresa_nombre, e.cif as empresa_cif
            FROM facturas f
            LEFT JOIN empresas e ON f.empresa_id = e.id
            ${whereClause}
            ORDER BY f.fecha_emision DESC
        `;

        const result = await db.query(query, params);

        res.json({
            success: true,
            data: result.rows
        });
    } catch (error) {
        console.error('Error en GET /facturas:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// GET /api/facturas/:id - Obtener detalle de factura
router.get('/:id', async (req, res) => {
    try {
        const result = await db.query(
            `SELECT f.*, 
                    e.nombre as empresa_nombre, 
                    e.cif as empresa_cif,
                    e.direccion as empresa_direccion,
                    e.email as empresa_email,
                    e.telefono as empresa_telefono
             FROM facturas f
             LEFT JOIN empresas e ON f.empresa_id = e.id
             WHERE f.id = $1`,
            [req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Factura no encontrada'
            });
        }

        // Obtener multas de la factura
        const multasResult = await db.query(
            `SELECT id, numero_expediente, matricula, 
                    fecha_infraccion, importe_multa, importe_gestion
             FROM multas
             WHERE empresa_id = $1
               AND facturada = true
               AND fecha_comunicacion_organismo >= $2
               AND fecha_comunicacion_organismo <= $3
             ORDER BY fecha_infraccion`,
            [
                result.rows[0].empresa_id,
                result.rows[0].periodo_inicio,
                result.rows[0].periodo_fin
            ]
        );

        res.json({
            success: true,
            data: {
                ...result.rows[0],
                multas: multasResult.rows
            }
        });
    } catch (error) {
        console.error('Error en GET /facturas/:id:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// POST /api/facturas/generar - Generar facturas del mes
router.post('/generar', async (req, res) => {
    try {
        const { mes, anio } = req.body;

        if (!mes || !anio) {
            return res.status(400).json({
                success: false,
                message: 'Mes y año son obligatorios'
            });
        }

        // Llamar a la función de PostgreSQL
        await db.query(
            'SELECT generar_facturas_mes($1, $2)',
            [mes, anio]
        );

        // Obtener las facturas generadas
        const result = await db.query(
            `SELECT f.*, e.nombre as empresa_nombre
             FROM facturas f
             LEFT JOIN empresas e ON f.empresa_id = e.id
             WHERE EXTRACT(MONTH FROM f.periodo_inicio) = $1
               AND EXTRACT(YEAR FROM f.periodo_inicio) = $2
             ORDER BY f.numero_factura`,
            [mes, anio]
        );

        res.json({
            success: true,
            message: `${result.rows.length} facturas generadas`,
            data: result.rows
        });
    } catch (error) {
        console.error('Error en POST /facturas/generar:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// PUT /api/facturas/:id/estado - Actualizar estado de factura
router.put('/:id/estado', async (req, res) => {
    try {
        const { estado } = req.body;

        if (!estado) {
            return res.status(400).json({
                success: false,
                message: 'El estado es obligatorio'
            });
        }

        const validEstados = ['pendiente', 'enviada', 'pagada', 'vencida', 'cancelada'];
        if (!validEstados.includes(estado)) {
            return res.status(400).json({
                success: false,
                message: `Estado inválido. Debe ser uno de: ${validEstados.join(', ')}`
            });
        }

        const result = await db.query(
            `UPDATE facturas 
             SET estado = $1
             WHERE id = $2
             RETURNING *`,
            [estado, req.params.id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Factura no encontrada'
            });
        }

        res.json({
            success: true,
            data: result.rows[0],
            message: 'Estado actualizado correctamente'
        });
    } catch (error) {
        console.error('Error en PUT /facturas/:id/estado:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

module.exports = router;
