const db = require('../config/database');
const microservicioClient = require('./microservicioClient');
const { cache } = require('../config/redis');

class MultasService {
    
    async crearMulta(data) {
        const client = await db.connect();
        
        try {
            await client.query('BEGIN');

            const {
                numero_expediente,
                matricula,
                fecha_infraccion,
                organismo_emisor,
                importe_multa
            } = data;

            // 1. Identificar empresa por matrícula
            const empresaResult = await client.query(
                `SELECT id, nombre, precio_gestion 
                 FROM empresas 
                 WHERE EXISTS (
                     SELECT 1 FROM vehiculos 
                     WHERE vehiculos.empresa_id = empresas.id 
                     AND vehiculos.matricula = $1
                 )`,
                [matricula]
            );

            if (empresaResult.rows.length === 0) {
                throw new Error(`No se encontró empresa para la matrícula ${matricula}`);
            }

            const empresa = empresaResult.rows[0];

            // 2. Crear multa inicial (sin conductor)
            const multaResult = await client.query(
                `INSERT INTO multas (
                    empresa_id, numero_expediente, matricula, 
                    fecha_infraccion, organismo_emisor, importe_multa,
                    estado, importe_gestion
                ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
                RETURNING *`,
                [
                    empresa.id,
                    numero_expediente,
                    matricula,
                    fecha_infraccion,
                    organismo_emisor,
                    importe_multa,
                    'pendiente_identificacion',
                    empresa.precio_gestion
                ]
            );

            const multa = multaResult.rows[0];

            await client.query('COMMIT');

            console.log(`✓ Multa ${numero_expediente} creada para empresa ${empresa.nombre}`);

            // 3. Iniciar proceso de identificación (async)
            this.identificarConductor(multa.id).catch(err => {
                console.error(`Error identificando conductor para multa ${multa.id}:`, err);
            });

            return {
                success: true,
                data: multa,
                message: 'Multa registrada, iniciando identificación de conductor'
            };

        } catch (error) {
            await client.query('ROLLBACK');
            console.error('Error creando multa:', error);
            throw error;
        } finally {
            client.release();
        }
    }

    async identificarConductor(multaId) {
        try {
            // Obtener datos de la multa
            const multaResult = await db.query(
                `SELECT m.*, e.id as empresa_id, v.dni_conductor
                 FROM multas m
                 JOIN empresas e ON m.empresa_id = e.id
                 LEFT JOIN vehiculos v ON m.matricula = v.matricula AND v.empresa_id = e.id
                 WHERE m.id = $1`,
                [multaId]
            );

            if (multaResult.rows.length === 0) {
                throw new Error('Multa no encontrada');
            }

            const multa = multaResult.rows[0];

            if (!multa.dni_conductor) {
                throw new Error('No se encontró DNI del conductor para esta matrícula');
            }

            // Consultar datos del conductor en el microservicio
            const conductorData = await microservicioClient.consultarConductor(
                multa.empresa_id,
                multa.dni_conductor
            );

            if (!conductorData) {
                await db.query(
                    `UPDATE multas 
                     SET estado = $1, 
                         observaciones = $2
                     WHERE id = $3`,
                    ['error_identificacion', 'Conductor no encontrado en sistema de empresa', multaId]
                );
                return;
            }

            // Actualizar multa con datos del conductor
            await db.query(
                `UPDATE multas 
                 SET conductor_dni = $1,
                     conductor_nombre = $2,
                     conductor_email = $3,
                     conductor_telefono = $4,
                     conductor_direccion = $5,
                     estado = $6
                 WHERE id = $7`,
                [
                    conductorData.dni,
                    `${conductorData.nombre} ${conductorData.apellidos}`,
                    conductorData.email,
                    conductorData.telefono,
                    `${conductorData.direccion}, ${conductorData.codigo_postal} ${conductorData.ciudad}`,
                    'conductor_identificado',
                    multaId
                ]
            );

            console.log(`✓ Conductor identificado para multa ${
