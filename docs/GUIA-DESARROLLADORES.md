# 📘 Guía para Desarrolladores

## Sistema de Gestión de Multas - Instrucciones Completas

**Equipo:** Oksana (Full Stack) + Maksym (Backend/DevOps)

---

## 🎯 Resumen del Proyecto

Sistema centralizado en AWS que gestiona el ciclo completo de multas de tráfico:

1. **Recibe notificación** de multa (matrícula, fecha, organismo)
2. **Identifica la empresa** dueña del vehículo
3. **Consulta el microservicio** de la empresa para obtener datos del conductor
4. **Comunica los datos** al organismo notificador
5. **Factura mensualmente** las gestiones realizadas

---

## 📦 Estructura del Repositorio

```
sistema-multas/
├── backend/              # API Central (Node.js + Express + PostgreSQL)
├── microservicio/        # API por Empresa (Docker)
├── database/            # Schemas y migraciones
├── scripts/             # Scripts de testing y deploy
└── docs/               # Documentación
```

---

## 🚀 Setup Inicial

### 1. Clonar repositorio

```bash
git clone https://github.com/Disi3664/sistema-multas.git
cd sistema-multas
```

### 2. Instalar PostgreSQL (si no lo tienes)

**Mac:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Linux:**
```bash
sudo apt-get install postgresql-15
sudo systemctl start postgresql
```

### 3. Crear base de datos

```bash
cd scripts
chmod +x init-database.sh
./init-database.sh
```

Esto creará:
- Base de datos `sistema_multas`
- Todas las tablas
- Función de facturación
- Datos de ejemplo

---

## 💻 Backend - API Central

### Setup

```bash
cd backend

# Copiar y configurar variables de entorno
cp .env.example .env
nano .env  # Editar con tus credenciales reales

# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev

# O en producción
npm start
```

### Variables de entorno (.env)

```env
PORT=3000
NODE_ENV=development

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=sistema_multas
DB_USER=postgres
DB_PASSWORD=tu_password

# Redis (si lo usas)
REDIS_HOST=localhost
REDIS_PORT=6379
```

### Testing

```bash
cd scripts
chmod +x test-backend.sh
./test-backend.sh
```

### Endpoints principales

#### Multas
- `POST /api/multas` - Crear multa
- `GET /api/multas` - Listar con filtros
- `GET /api/multas/:id` - Detalle
- `PUT /api/multas/:id/estado` - Actualizar estado
- `POST /api/multas/:id/comunicar` - Comunicar al organismo
- `GET /api/multas/stats/general` - Estadísticas

#### Empresas
- `GET /api/empresas` - Listar
- `GET /api/empresas/:id` - Detalle
- `POST /api/empresas` - Crear
- `PUT /api/empresas/:id` - Actualizar
- `POST /api/empresas/:id/verificar-conexion` - Test microservicio

#### Facturas
- `GET /api/facturas` - Listar
- `GET /api/facturas/:id` - Detalle
- `POST /api/facturas/generar` - Generar facturas mes
- `PUT /api/facturas/:id/estado` - Actualizar estado

---

## 🐳 Microservicio - API Empresa

### Setup

```bash
cd microservicio

# Configurar variables
cp .env.example .env
nano .env

# Con Docker
docker-compose up -d

# Sin Docker (desarrollo)
npm install
npm run dev
```

### Variables de entorno (.env)

```env
PORT=3001

# Base de datos de la empresa (MySQL/PostgreSQL)
DB_HOST=localhost
DB_PORT=3306
DB_USER=empresa_user
DB_PASSWORD=empresa_password
DB_NAME=empresa_transportes

# API Key (debe coincidir con la del sistema central)
API_KEY=empresa_a_key_12345abcdef
```

### Testing

```bash
cd scripts
chmod +x test-microservicio.sh
./test-microservicio.sh
```

### Schema requerido en BD de empresa

El microservicio espera esta tabla en la base de datos de la empresa:

```sql
CREATE TABLE conductores (
    id INT PRIMARY KEY AUTO_INCREMENT,
    dni VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellidos VARCHAR(200) NOT NULL,
    email VARCHAR(255),
    telefono VARCHAR(20),
    direccion TEXT,
    codigo_postal VARCHAR(10),
    ciudad VARCHAR(100),
    provincia VARCHAR(100),
    activo TINYINT(1) DEFAULT 1
);
```

---

## 🔄 Flujo de Trabajo

### Fase 1: Base de Datos (Día 1-2)

**Responsable:** Maksym

1. Ejecutar `scripts/init-database.sh`
2. Verificar que todas las tablas se crearon
3. Revisar función `generar_facturas_mes()`
4. Insertar datos de prueba adicionales si es necesario

**Verificación:**
```bash
psql -d sistema_multas -c "\dt"
psql -d sistema_multas -c "SELECT * FROM empresas;"
```

---

### Fase 2: Microservicio (Día 3-4)

**Responsable:** Maksym

1. Configurar base de datos de empresa de prueba
2. Crear tabla `conductores` en BD empresa
3. Insertar conductores de prueba
4. Configurar `.env` del microservicio
5. Levantar microservicio con Docker
6. Ejecutar tests

**Verificación:**
```bash
curl http://localhost:3001/health
./scripts/test-microservicio.sh
```

---

### Fase 3: Backend Central (Día 5-7)

**Responsable:** Oksana

1. Configurar `.env` del backend
2. Instalar dependencias
3. Levantar backend en desarrollo
4. Probar endpoints con Postman/Thunder Client
5. Verificar integración con microservicio

**Pasos clave:**

```bash
# 1. Crear una empresa
curl -X POST http://localhost:3000/api/empresas \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Transportes Test",
    "cif": "B99999999",
    "email": "test@test.com",
    "api_url": "http://localhost:3001",
    "api_key": "empresa_a_key_12345abcdef"
  }'

# 2. Crear una multa
curl -X POST http://localhost:3000/api/multas \
  -H "Content-Type: application/json" \
  -d '{
    "numero_expediente": "EXP001",
    "matricula": "1234ABC",
    "fecha_infraccion": "2025-10-01",
    "organismo_emisor": "DGT",
    "importe_multa": 200.00
  }'

# 3. Ver el estado de la multa
curl http://localhost:3000/api/multas/1
```

---

### Fase 4: Sistema de Facturación (Día 8-9)

**Responsables:** Ambos

1. Crear multas de prueba para diferentes empresas
2. Marcarlas como comunicadas al organismo
3. Generar facturas del mes

```bash
# Generar facturas de octubre 2025
curl -X POST http://localhost:3000/api/facturas/generar \
  -H "Content-Type: application/json" \
  -d '{"mes": 10, "anio": 2025}'

# Ver facturas generadas
curl http://localhost:3000/api/facturas
```

---

### Fase 5: Testing e Integración (Día 10)

**Responsables:** Ambos

1. Ejecutar todos los scripts de testing
2. Probar flujo completo end-to-end
3. Verificar que la facturación funciona correctamente
4. Documentar cualquier bug encontrado
5. Preparar para despliegue

**Script de testing completo:**

```bash
cd scripts

# Test microservicio
./test-microservicio.sh

# Test backend
./test-backend.sh

# Test manual del flujo completo
# (crear multa, identificar conductor, comunicar, facturar)
```

---

## 🐛 Debugging

### Backend no arranca

```bash
# Verificar que PostgreSQL está corriendo
psql -U postgres -c "SELECT version();"

# Ver logs del backend
npm run dev  # En modo desarrollo muestra más logs

# Verificar conexión a BD
psql -d sistema_multas -c "SELECT COUNT(*) FROM empresas;"
```

### Microservicio no responde

```bash
# Ver logs del contenedor
docker-compose logs -f

# Verificar que está corriendo
docker-compose ps

# Reiniciar
docker-compose restart

# Verificar conexión a BD de empresa
# Conectar manualmente y probar query
```

### Error "Conductor no encontrado"

1. Verificar que existe el conductor en la BD de la empresa
2. Verificar que el DNI en la tabla `vehiculos` coincide
3. Verificar que la API Key es correcta
4. Ver logs del microservicio

---

## 📚 Recursos Adicionales

### Documentación de la API

Usar Postman o Thunder Client con esta colección de pruebas.

### Diagramas

Ver `docs/arquitectura-completa.md` para diagramas detallados.

### Base de Datos

Ver `database/schema-completo.sql` con comentarios explicativos.

---

## ✅ Checklist de Implementación

### Backend
- [ ] BD PostgreSQL configurada
- [ ] Schema ejecutado correctamente
- [ ] Backend levantado y respondiendo
- [ ] Tests de endpoints pasando
- [ ] Integración con microservicio funcionando

### Microservicio
- [ ] Docker funcionando
- [ ] BD de empresa configurada
- [ ] Tabla conductores creada con datos
- [ ] Microservicio respondiendo
- [ ] Tests pasando

### Integración
- [ ] Backend puede comunicarse con microservicio
- [ ] Flujo completo de multa funciona
- [ ] Sistema de facturación genera correctamente
- [ ] Testing end-to-end completado

---

## 🆘 Contacto

Para cualquier duda durante la implementación, contactar con el responsable del proyecto.

---

## 📝 Notas Importantes

1. **Nunca commitear archivos `.env`** con credenciales reales
2. **Usar `.env.example`** como plantilla
3. **Documentar** cualquier cambio importante en este documento
4. **Hacer commits descriptivos** explicando qué se implementó
5. **Testing continuo** - probar cada componente según se desarrolla

---

**¡Éxito con la implementación! 🚀**
