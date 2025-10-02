#!/bin/bash

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-sistema_multas}"
DB_USER="${DB_USER:-postgres}"

echo "════════════════════════════════════════════════════════════════"
echo "🗄️  Inicialización de Base de Datos"
echo "════════════════════════════════════════════════════════════════"
echo ""

if ! command -v psql &> /dev/null; then
    echo "❌ Error: psql no está instalado"
    exit 1
fi

echo "→ Verificando conexión..."
if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres -c '\q' 2>/dev/null; then
    echo "❌ Error: No se puede conectar a PostgreSQL"
    exit 1
fi
echo "✓ Conexión establecida"
echo ""

echo "→ Creando base de datos..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d postgres << EOSQL
SELECT 'CREATE DATABASE $DB_NAME'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec
EOSQL

echo "✓ Base de datos verificada"
echo ""

echo "→ Ejecutando schema..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f ../database/schema-completo.sql

if [ $? -eq 0 ]; then
    echo "✓ Schema ejecutado"
else
    echo "❌ Error ejecutando schema"
    exit 1
fi

echo ""
echo "✅ Base de datos inicializada"
