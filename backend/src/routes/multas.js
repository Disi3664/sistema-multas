const express = require('express');
const router = express.Router();
const multasService = require('../services/multasService');

// POST /api/multas - Crear nueva multa
router.post('/', async (req, res) => {
    try {
        const resultado = await multasService.crearMulta(req.body);
        res.status(201).json(resultado);
    } catch (error) {
        console.error('Error en POST /multas:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// GET /api/multas - Listar multas con filtros
router.get('/', async (req, res) => {
    try {
        const { 
            empresa_id, 
            estado, 
            matricula, 
            fecha_desde, 
            fecha_hasta,
            facturada,
            pagina = 1, 
            limite = 20 
        } = req.query;

        const filtros = {
            empresa_id,
            estado,
            matricula,
            fecha_desde,
            fecha_hasta,
            facturada: facturada !== undefined ? facturada === 'true' : undefined
        };

        const resultado = await multasService.listarMultas(
            filtros, 
            parseInt(pagina), 
            parseInt(limite)
        );

        res.json(resultado);
    } catch (error) {
        console.error('Error en GET /multas:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// GET /api/multas/:id - Obtener detalle de una multa
router.get('/:id', async (req, res) => {
    try {
        const resultado = await multasService.obtenerMulta(req.params.id);
        
        if (!resultado.success) {
            return res.status(404).json(resultado);
        }

        res.json(resultado);
    } catch (error) {
        console.error('Error en GET /multas/:id:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// PUT /api/multas/:id/estado - Actualizar estado de multa
router.put('/:id/estado', async (req, res) => {
    try {
        const { estado, observaciones } = req.body;

        if (!estado) {
            return res.status(400).json({ 
                success: false, 
                message: 'El campo estado es requerido' 
            });
        }

        const resultado = await multasService.actualizarEstado(
            req.params.id, 
            estado, 
            observaciones
        );

        if (!resultado.success) {
            return res.status(404).json(resultado);
        }

        res.json(resultado);
    } catch (error) {
        console.error('Error en PUT /multas/:id/estado:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// POST /api/multas/:id/comunicar - Comunicar datos al organismo
router.post('/:id/comunicar', async (req, res) => {
    try {
        const resultado = await multasService.comunicarOrganismo(req.params.id);
        res.json(resultado);
    } catch (error) {
        console.error('Error en POST /multas/:id/comunicar:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

// GET /api/multas/estadisticas - Obtener estadísticas
router.get('/stats/general', async (req, res) => {
    try {
        const { empresa_id, fecha_inicio, fecha_fin } = req.query;

        const resultado = await multasService.obtenerEstadisticas(
            empresa_id,
            fecha_inicio,
            fecha_fin
        );

        res.json(resultado);
    } catch (error) {
        console.error('Error en GET /multas/stats:', error);
        res.status(500).json({ 
            success: false, 
            message: error.message 
        });
    }
});

module.exports = router;
