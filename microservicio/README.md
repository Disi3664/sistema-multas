# Microservicio API Empresa

## Instalación

```bash
npm install
```

## Configuración

1. Copiar `.env.example` a `.env`
2. Configurar credenciales de BD de la empresa
3. Generar API_KEY único

## Iniciar

```bash
# Con Node.js
node src/server.js

# Con Docker
docker-compose up -d
```

## Archivos a copiar

Copiar de Artefacto #2:
- `src/server.js`
- `src/config/database.js`
- `src/middleware/auth.js`
- `src/routes/conductor.js`
