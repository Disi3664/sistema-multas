const axios = require('axios');
const { cache } = require('../config/redis');

class MicroservicioClient {
    
    async consultarConductor(empresaId, dni) {
        try {
            // Buscar en cache primero
            const cacheKey = `conductor:${empresaId}:${dni}`;
            const cached = await cache.get(cacheKey);
            
            if (cached) {
                console.log(`✓ Conductor ${dni} obtenido de cache`);
                return cached;
            }

            // Obtener configuración del microservicio de la empresa
            const db = require('../config/database');
            const { rows } = await db.query(
                'SELECT api_url, api_key FROM empresas WHERE id = $1 AND activo = true',
                [empresaId]
            );

            if (rows.length === 0) {
                throw new Error('Empresa no encontrada o inactiva');
            }

            const { api_url, api_key } = rows[0];

            if (!api_url || !api_key) {
                throw new Error('Empresa sin configuración de API');
            }

            // Consultar microservicio
            console.log(`→ Consultando microservicio de empresa ${empresaId} para DNI ${dni}`);
            
            const response = await axios.get(
                `${api_url}/api/conductor`,
                {
                    params: { dni },
                    headers: { 'X-API-Key': api_key },
                    timeout: 5000
                }
            );

            if (response.data.success && response.data.data) {
                const conductorData = response.data.data;
                
                // Guardar en cache por 1 hora
                await cache.set(cacheKey, conductorData, 3600);
                
                console.log(`✓ Conductor ${dni} encontrado`);
                return conductorData;
            }

            return null;

        } catch (error) {
            if (error.response) {
                // Error de respuesta del microservicio
                console.error(`✗ Error del microservicio: ${error.response.status}`, error.response.data);
                
                if (error.response.status === 404) {
                    return null; // Conductor no encontrado
                }
            } else if (error.request) {
                // No hubo respuesta
                console.error('✗ No se pudo contactar con el microservicio:', error.message);
            } else {
                // Error en la configuración de la petición
                console.error('✗ Error configurando petición:', error.message);
            }
            
            throw new Error(`Error consultando microservicio: ${error.message}`);
        }
    }

    async verificarConexion(empresaId) {
        try {
            const db = require('../config/database');
            const { rows } = await db.query(
                'SELECT api_url, api_key FROM empresas WHERE id = $1',
                [empresaId]
            );

            if (rows.length === 0) {
                return { success: false, message: 'Empresa no encontrada' };
            }

            const { api_url, api_key } = rows[0];

            const response = await axios.get(
                `${api_url}/health`,
                { timeout: 3000 }
            );

            if (response.status === 200) {
                return { 
                    success: true, 
                    message: 'Microservicio disponible',
                    data: response.data 
                };
            }

            return { success: false, message: 'Microservicio no responde correctamente' };

        } catch (error) {
            return { 
                success: false, 
                message: `Error: ${error.message}` 
            };
        }
    }
}

module.exports = new MicroservicioClient();
