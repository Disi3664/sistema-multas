# Backend Sistema Central

## Instalación

```bash
npm install
```

## Configuración

1. Copiar `.env.example` a `.env`
2. Configurar variables con datos reales
3. Generar JWT_SECRET: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`

## Iniciar

```bash
# Desarrollo
npm run dev

# Producción
npm start
```

## Archivos a copiar

Los siguientes archivos deben copiarse de los artefactos:

- `src/index.js` → Artefacto #6
- `src/services/multasService.js` → Artefacto #3
- `src/services/microservicioClient.js` → Artefacto #4
- `src/routes/auth.js` → Artefacto #11
- `src/routes/multas.js` → Artefacto #5
- `src/routes/empresas.js` → Artefacto #9
- `src/routes/facturas.js` → Artefacto #10
