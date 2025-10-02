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
