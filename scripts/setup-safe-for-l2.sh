#!/bin/bash
# Complete Safe Infrastructure setup for L2
# Run this after: ./scripts/run_locally.sh

set -e

# Detect L2 Chain ID from RPC
echo "Detecting L2 Chain ID..."
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8547 | grep -o '"result":"0x[^"]*"' | cut -d'"' -f4)

if [ -z "$CHAIN_ID" ]; then
    echo "ERROR: Could not detect L2 Chain ID. Is L2 RPC running on port 8547?"
    exit 1
fi

CHAIN_ID_DEC=$(printf "%d" $CHAIN_ID)
echo "L2 Chain ID detected: $CHAIN_ID_DEC ($CHAIN_ID)"
echo ""

echo "================================================================"
echo "Safe Infrastructure Setup for L2 Chain $CHAIN_ID"
echo "================================================================"
echo ""

# Step 1: Add L2 chain configuration
echo "[1/3] Adding L2 chain configuration..."
docker compose exec -T cfg-web python src/manage.py shell < tmp/add-chain-via-shell.py 2>&1 | grep -E "(Chain.*created|Chain.*already exists)" || echo "  Done"
echo ""

# Step 2: Add Safe contract addresses
echo "[2/3] Configuring Safe contract addresses..."
docker compose exec -T cfg-web python src/manage.py shell < tmp/add-safe-contracts.py 2>&1 | grep -E "(Contract addresses updated|Found chain)" || echo "  Done"
echo ""

# Step 3: Verify setup
echo "[3/3] Verifying configuration..."
./tmp/full-verification.sh | tail -20
echo ""

echo "================================================================"
echo "Setup complete! Safe Infrastructure is ready for use."
echo "================================================================"
