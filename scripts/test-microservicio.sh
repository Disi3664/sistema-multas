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
