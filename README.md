# Sistema de Gestión de Multas

Sistema centralizado para gestión de multas de tráfico con arquitectura distribuida.

## Estructura del Proyecto

```
sistema-multas/
├── backend/           # Backend Node.js + Express + PostgreSQL
├── microservicio/     # Microservicio Docker por empresa cliente
├── database/          # Scripts SQL PostgreSQL
├── scripts/           # Scripts de testing y deployment
├── docs/              # Documentación completa
└── deploy/            # Archivos de configuración AWS
```

## Tecnologías

- **Backend:** Node.js 18+, Express, PostgreSQL 15+
- **Microservicio:** Node.js, Docker, MySQL
- **Cloud:** AWS (RDS, EC2, S3)
- **Autenticación:** JWT

## Inicio Rápido

1. **Leer documentación:**
   ```bash
   cat docs/MAPEO-ARTEFACTOS.md
   cat docs/guia-desde-bd.md
   ```

2. **Copiar artefactos:** Según tabla de mapeo

3. **Configurar backend:**
   ```bash
   cd backend
   cp .env.example .env
   # Editar .env con datos reales
   npm install
   npm start
   ```

4. **Configurar microservicio:**
   ```bash
   cd microservicio
   cp .env.example .env
   # Editar .env
   docker-compose up -d
   ```

## Equipo

- **Oksana** - Full Stack Developer
- **Maksym** - Backend/DevOps Engineer

## Licencia

MIT
