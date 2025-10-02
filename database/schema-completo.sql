-- ============================================
-- SCHEMA COMPLETO - Sistema de Gestión de Multas
-- PostgreSQL 15+
-- ============================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLA: empresas
-- ============================================
CREATE TABLE empresas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    cif VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    telefono VARCHAR(20),
    direccion TEXT,
    activo BOOLEAN DEFAULT true,
    api_url VARCHAR(500),
    api_key VARCHAR(255) UNIQUE,
    servicio_recurso BOOLEAN DEFAULT false,
    precio_gestion DECIMAL(10,2) DEFAULT 15.00,
    precio_recurso DECIMAL(10,2) DEFAULT 150.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE empresas IS 'Empresas de transporte clientes del sistema';
COMMENT ON COLUMN empresas.api_url IS 'URL del microservicio de la empresa';
COMMENT ON COLUMN empresas.api_key IS 'API Key para autenticar con el microservicio';
COMMENT ON COLUMN empresas.servicio_recurso IS 'Si la empresa tiene contratado servicio de recursos';

-- ============================================
-- TABLA: vehiculos
-- ============================================
CREATE TABLE vehiculos (
    id SERIAL PRIMARY KEY,
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE CASCADE,
    matricula VARCHAR(20) NOT NULL,
    dni_conductor VARCHAR(20),
    marca VARCHAR(100),
    modelo VARCHAR(100),
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(empresa_id, matricula)
);

CREATE INDEX idx_vehiculos_empresa ON vehiculos(empresa_id);
CREATE INDEX idx_vehiculos_matricula ON vehiculos(matricula);

COMMENT ON TABLE vehiculos IS 'Vehículos asociados a cada empresa';

-- ============================================
-- TABLA: multas
-- ============================================
CREATE TABLE multas (
    id SERIAL PRIMARY KEY,
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE CASCADE,
    numero_expediente VARCHAR(50) UNIQUE NOT NULL,
    matricula VARCHAR(20) NOT NULL,
    fecha_infraccion DATE NOT NULL,
    organismo_emisor VARCHAR(255),
    importe_multa DECIMAL(10,2),
    
    -- Datos del conductor
    conductor_dni VARCHAR(20),
    conductor_nombre VARCHAR(255),
    conductor_email VARCHAR(255),
    conductor_telefono VARCHAR(20),
    conductor_direccion TEXT,
    
    -- Control de estado
    estado VARCHAR(50) DEFAULT 'pendiente_identificacion',
    fecha_comunicacion_organismo TIMESTAMP,
    observaciones TEXT,
    
    -- Facturación
    importe_gestion DECIMAL(10,2),
    facturable BOOLEAN DEFAULT true,
    facturada BOOLEAN DEFAULT false,
    factura_id INTEGER REFERENCES facturas(id),
    
    -- Recurso (opcional)
    recurso_presentado BOOLEAN DEFAULT false,
    fecha_recurso TIMESTAMP,
    importe_recurso DECIMAL(10,2),
    recurso_facturable BOOLEAN DEFAULT false,
    recurso_facturado BOOLEAN DEFAULT false,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_multas_empresa ON multas(empresa_id);
CREATE INDEX idx_multas_matricula ON multas(matricula);
CREATE INDEX idx_multas_fecha ON multas(fecha_infraccion);
CREATE INDEX idx_multas_estado ON multas(estado);
CREATE INDEX idx_multas_facturada ON multas(facturada);

COMMENT ON TABLE multas IS 'Registro de todas las multas gestionadas';
COMMENT ON COLUMN multas.estado IS 'Estados: pendiente_identificacion, conductor_identificado, comunicado_organismo, error_identificacion';

-- ============================================
-- TABLA: facturas
-- ============================================
CREATE TABLE facturas (
    id SERIAL PRIMARY KEY,
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE CASCADE,
    numero_factura VARCHAR(50) UNIQUE NOT NULL,
    periodo_inicio DATE NOT NULL,
    periodo_fin DATE NOT NULL,
    fecha_emision DATE NOT NULL,
    fecha_vencimiento DATE NOT NULL,
    
    -- Gestiones
    total_gestiones INTEGER DEFAULT 0,
    importe_gestiones DECIMAL(10,2) DEFAULT 0,
    
    -- Recursos (opcional)
    total_recursos INTEGER DEFAULT 0,
    importe_recursos DECIMAL(10,2) DEFAULT 0,
    
    -- Totales
    descuento_aplicado DECIMAL(10,2) DEFAULT 0,
    subtotal DECIMAL(10,2) NOT NULL,
    iva_importe DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) NOT NULL,
    
    estado VARCHAR(50) DEFAULT 'pendiente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_facturas_empresa ON facturas(empresa_id);
CREATE INDEX idx_facturas_fecha ON facturas(fecha_emision);
CREATE INDEX idx_facturas_estado ON facturas(estado);

COMMENT ON TABLE facturas IS 'Facturas mensuales generadas por gestiones';
COMMENT ON COLUMN facturas.estado IS 'Estados: pendiente, enviada, pagada, vencida, cancelada';

-- ============================================
-- TABLA: descuentos_volumen
-- ============================================
CREATE TABLE descuentos_volumen (
    id SERIAL PRIMARY KEY,
    empresa_id INTEGER REFERENCES empresas(id) ON DELETE CASCADE,
    desde_gestiones INTEGER NOT NULL,
    porcentaje_descuento DECIMAL(5,2) NOT NULL,
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_descuentos_empresa ON descuentos_volumen(empresa_id);

COMMENT ON TABLE descuentos_volumen IS 'Descuentos por volumen de gestiones para cada empresa';

-- ============================================
-- FUNCIÓN: Generar facturas del mes
-- ============================================
CREATE OR REPLACE FUNCTION generar_facturas_mes(p_mes INTEGER, p_anio INTEGER)
RETURNS void AS $$
DECLARE
    empresa_rec RECORD;
    periodo_inicio DATE;
    periodo_fin DATE;
    total_gest INTEGER;
    importe_gest DECIMAL(10,2);
    total_rec INTEGER;
    importe_rec DECIMAL(10,2);
    porcentaje_desc DECIMAL(5,2);
    descuento_calc DECIMAL(10,2);
    subtotal_calc DECIMAL(10,2);
    iva_calc DECIMAL(10,2);
    total_calc DECIMAL(10,2);
    num_factura VARCHAR(50);
BEGIN
    -- Calcular periodo
    periodo_inicio := make_date(p_anio, p_mes, 1);
    periodo_fin := (periodo_inicio + INTERVAL '1 month' - INTERVAL '1 day')::DATE;
    
    RAISE NOTICE 'Generando facturas para periodo: % - %', periodo_inicio, periodo_fin;
    
    -- Iterar sobre empresas activas
    FOR empresa_rec IN
        SELECT * FROM empresas WHERE activo = true
    LOOP
        -- Contar gestiones del mes
        SELECT COUNT(*), COALESCE(SUM(importe_gestion), 0)
        INTO total_gest, importe_gest
        FROM multas
        WHERE empresa_id = empresa_rec.id
          AND fecha_comunicacion_organismo >= periodo_inicio
          AND fecha_comunicacion_organismo <= periodo_fin
          AND facturable = true
          AND facturada = false;
        
        -- Si no hay gestiones, saltar
        IF total_gest = 0 THEN
            RAISE NOTICE 'Empresa % sin gestiones este mes', empresa_rec.nombre;
            CONTINUE;
        END IF;
        
        -- Obtener descuento por volumen
        SELECT COALESCE(MAX(porcentaje_descuento), 0)
        INTO porcentaje_desc
        FROM descuentos_volumen
        WHERE descuentos_volumen.empresa_id = empresa_rec.id
          AND desde_gestiones <= total_gest
          AND activo = true;
        
        descuento_calc := importe_gest * (porcentaje_desc / 100);
        
        -- Contar recursos (si la empresa tiene el servicio)
        total_rec := 0;
        importe_rec := 0;
        
        IF empresa_rec.servicio_recurso THEN
            SELECT COUNT(*), COALESCE(SUM(importe_recurso), 0)
            INTO total_rec, importe_rec
            FROM multas
            WHERE multas.empresa_id = empresa_rec.id
              AND fecha_recurso >= periodo_inicio
              AND fecha_recurso <= periodo_fin
              AND recurso_facturable = true
              AND recurso_facturado = false;
        END IF;
        
        -- Calcular totales
        subtotal_calc := importe_gest - descuento_calc + importe_rec;
        iva_calc := subtotal_calc * 0.21;
        total_calc := subtotal_calc + iva_calc;
        
        -- Generar número de factura
        num_factura := 'FACT-' || p_anio || LPAD(p_mes::TEXT, 2, '0') || '-' || LPAD(empresa_rec.id::TEXT, 4, '0');
        
        -- Crear factura
        INSERT INTO facturas (
            empresa_id, numero_factura, periodo_inicio, periodo_fin,
            fecha_emision, fecha_vencimiento,
            total_gestiones, importe_gestiones,
            total_recursos, importe_recursos,
            descuento_aplicado, subtotal, iva_importe, total,
            estado
        ) VALUES (
            empresa_rec.id,
            num_factura,
            periodo_inicio,
            periodo_fin,
            periodo_fin,
            periodo_fin + INTERVAL '30 days',
            total_gest,
            importe_gest,
            total_rec,
            importe_rec,
            descuento_calc,
            subtotal_calc,
            iva_calc,
            total_calc,
            'pendiente'
        );
        
        -- Marcar multas como facturadas
        UPDATE multas
        SET facturada = true,
            factura_id = (SELECT id FROM facturas WHERE numero_factura = num_factura)
        WHERE empresa_id = empresa_rec.id
          AND fecha_comunicacion_organismo >= periodo_inicio
          AND fecha_comunicacion_organismo <= periodo_fin
          AND facturable = true
          AND facturada = false;
        
        -- Marcar recursos como facturados
        IF empresa_rec.servicio_recurso AND total_rec > 0 THEN
            UPDATE multas
            SET recurso_facturado = true
            WHERE empresa_id = empresa_rec.id
              AND fecha_recurso >= periodo_inicio
              AND fecha_recurso <= periodo_fin
              AND recurso_facturable = true
              AND recurso_facturado = false;
        END IF;
        
        RAISE NOTICE 'Factura % generada: % gestiones, Total: %€', 
                     num_factura, total_gest, total_calc;
    END LOOP;
    
    RAISE NOTICE 'Proceso de facturación completado';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_empresas_updated_at
    BEFORE UPDATE ON empresas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_multas_updated_at
    BEFORE UPDATE ON multas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- DATOS DE EJEMPLO
-- ============================================

-- Insertar empresa de ejemplo
INSERT INTO empresas (nombre, cif, email, telefono, api_url, api_key, servicio_recurso, precio_gestion) 
VALUES (
    'Transportes Ejemplo S.L.', 
    'B12345678', 
    'info@ejemplo.com',
    '912345678',
    'http://localhost:3001',
    'empresa_a_key_12345abcdef',
    true,
    15.00
) ON CONFLICT (cif) DO NOTHING;

-- Insertar descuentos por volumen
INSERT INTO descuentos_volumen (empresa_id, desde_gestiones, porcentaje_descuento)
SELECT id, 50, 5.00 FROM empresas WHERE cif = 'B12345678'
UNION ALL
SELECT id, 100, 10.00 FROM empresas WHERE cif = 'B12345678'
UNION ALL
SELECT id, 200, 15.00 FROM empresas WHERE cif = 'B12345678';

-- Insertar vehículos de ejemplo
INSERT INTO vehiculos (empresa_id, matricula, dni_conductor, marca, modelo)
SELECT id, '1234ABC', '12345678A', 'Mercedes', 'Sprinter' 
FROM empresas WHERE cif = 'B12345678';

RAISE NOTICE 'Schema creado correctamente con datos de ejemplo';
