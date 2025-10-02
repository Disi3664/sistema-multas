#!/bin/bash

################################################################################
# PARTE 3: Crear Scripts y preparar para commit
################################################################################

echo "════════════════════════════════════════════════════════════════"
echo "🗄️  PARTE 3: Creando scripts de testing"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verificar ubicación
if [ ! -d ".git" ]; then
    echo "❌ Error: Ejecutar desde carpeta sistema-multas"
    exit 1
fi

# 1. test-microservicio.sh
cat > scripts/test-microservicio.sh << 'EOF'
#!/bin/bash

API_URL="${API_URL:-http://localhost:3001}"
API_KEY="${API_KEY:-empresa_a_key_12345abcdef}"

echo "════════════════════════════════════════════════════════════════"
echo "🧪 Testing Microservicio API Empresa"
echo "════════════════════════════════════════════════════════════════"
echo "API URL: $API_URL"
echo ""

echo "✓ Test 1: Health Check"
curl -s "$API_URL/health" | jq .
echo ""

echo "✓ Test 2: Sin API Key (debe dar 401)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null "$API_URL/api/conductor?dni=12345678A")
if [ "$HTTP_CODE" -eq 401 ]; then
    echo "✅ PASS - 401"
else
    echo "❌ FAIL - Esperaba 401, obtuvo $HTTP_CODE"
fi
echo ""

echo "✓ Test 3: API Key inválida (debe dar 403)"
HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null \
    -H "X-API-Key: clave_incorrecta" \
    "$API_URL/api/conductor?dni=12345678A")
if [ "$HTTP_CODE" -eq 403 ]; then
    echo "✅ PASS - 403"
else
    echo "❌ FAIL - Esperaba 403, obtuvo $HTTP_CODE"
fi
echo ""

echo "✓ Test 4: Consultar conductor"
curl -s -H "X-API-Key: $API_KEY" \
    "$API_URL/api/conductor?dni=12345678A" | jq .
echo ""

echo "✅ Tests completados"
EOF

chmod +x scripts/test-microservicio.sh
echo "✓ scripts/test-microservicio.sh"

# 2. test-backend.sh
cat > scripts/test-backend.sh << 'EOF'
#!/bin/bash

API_URL="${API_URL:-http://localhost:3000}"

echo "════════════════════════════════════════════════════════════════"
echo "🧪 Testing Backend Sistema Central"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "✓ Test 1: Health Check"
curl -s "$API_URL/health" | jq .
echo ""

echo "✓ Test 2: Listar empresas"
curl -s "$API_URL/api/empresas" | jq '.data | length'
echo " empresas encontradas"
echo ""

echo "✓ Test 3: Estadísticas"
curl -s "$API_URL/api/multas/stats/general" | jq .
echo ""

echo "✅ Tests completados"
EOF

chmod +x scripts/test-backend.sh
echo "✓ scripts/test-backend.sh"

# 3. init-database.sh
cat > scripts/init-database.sh << 'EOF'
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
EOF

chmod +x scripts/init-database.sh
echo "✓ scripts/init-database.sh"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ PARTE 3 COMPLETADA - Scripts creados"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "IMPORTANTE: Antes de hacer commit, asegúrate de haber copiado:"
echo ""
echo "  ✓ database/schema-completo.sql (Artefacto: database_schema_completo)"
echo "  ✓ docs/GUIA-DESARROLLADORES.md (Artefacto: doc_guia_desarrolladores)"
echo "  ✓ Los 5 archivos del backend mencionados en PARTE 2"
echo ""
echo "Cuando todo esté listo:"
echo "  git add ."
echo "  git commit -m 'feat: Código completo del sistema'"
echo "  git push origin main"
