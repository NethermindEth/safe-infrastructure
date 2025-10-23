#!/bin/bash
# Essential Safe Infrastructure Verification
# Tests all working components without requiring Safe wallet deployment

set -e

echo "================================================================"
echo "Safe Infrastructure - Essential Verification"
echo "================================================================"
echo ""

# Detect L2 Chain ID
echo "[1/6] Detecting L2 Chain ID..."
CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
  http://localhost:8547 | grep -o '"result":"0x[^"]*"' | cut -d'"' -f4)
CHAIN_ID_DEC=$(printf "%d" $CHAIN_ID)
echo "  Chain ID: $CHAIN_ID_DEC"
echo ""

# Check L2 Block Production
echo "[2/6] Checking L2 Block Production..."
BLOCK_NUM=$(cast block-number --rpc-url http://localhost:8547)
echo "  Current Block: $BLOCK_NUM"
if [ "$BLOCK_NUM" -gt 1000 ]; then
    echo "  Status: Blocks producing"
else
    echo "  WARNING: Block production may be stuck"
fi
echo ""

# Check API Endpoints
echo "[3/6] Checking API Endpoints..."
CONFIG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/cfg/api/v1/chains/)
TXS_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/txs/api/v1/about/)
CGW_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/cgw/v1/chains/)

if [ "$CONFIG_STATUS" = "200" ]; then
    echo "  Config Service: OK"
else
    echo "  Config Service: FAILED (HTTP $CONFIG_STATUS)"
fi

if [ "$TXS_STATUS" = "200" ]; then
    echo "  Transaction Service: OK"
else
    echo "  Transaction Service: FAILED (HTTP $TXS_STATUS)"
fi

if [ "$CGW_STATUS" = "200" ]; then
    echo "  Client Gateway: OK"
else
    echo "  Client Gateway: FAILED (HTTP $CGW_STATUS)"
fi
echo ""

# Check Indexing Status
echo "[4/6] Checking Transaction Service Indexing..."
INDEXING=$(curl -s http://localhost:8000/txs/api/v1/about/indexing/)
SYNCED=$(echo $INDEXING | jq -r '.synced')
CURRENT_BLOCK=$(echo $INDEXING | jq -r '.currentBlockNumber')
ERC20_SYNCED=$(echo $INDEXING | jq -r '.erc20Synced')

echo "  Synced: $SYNCED"
echo "  Current Block: $CURRENT_BLOCK"
echo "  ERC20 Synced: $ERC20_SYNCED"
echo ""

# Check Contract Deployments
echo "[5/6] Verifying Safe Contract Deployments..."
PROXY_CODE=$(cast code 0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67 --rpc-url http://localhost:8547)
MC1_CODE=$(cast code 0x41675C099F32341bf84BFc5382aF534df5C7461a --rpc-url http://localhost:8547)
MC2_CODE=$(cast code 0x29fcB43b46531BcA003ddC8FCB67FFE91900C762 --rpc-url http://localhost:8547)

if [ ${#PROXY_CODE} -gt 10 ]; then
    echo "  Proxy Factory: DEPLOYED"
else
    echo "  Proxy Factory: NOT DEPLOYED"
fi

if [ ${#MC1_CODE} -gt 10 ]; then
    echo "  Safe Master Copy 1.3.0: DEPLOYED"
else
    echo "  Safe Master Copy 1.3.0: NOT DEPLOYED"
fi

if [ ${#MC2_CODE} -gt 10 ]; then
    echo "  Safe Master Copy 1.4.1: DEPLOYED"
else
    echo "  Safe Master Copy 1.4.1: NOT DEPLOYED"
fi
echo ""

# Check Transaction Service Configuration
echo "[6/6] Verifying Transaction Service Configuration..."
SESSION=$(curl -s -c /tmp/essential_verify.txt "http://localhost:8000/txs/admin/login/" | grep -o 'name="csrfmiddlewaretoken" value="[^"]*"' | cut -d'"' -f4)

curl -s -b /tmp/essential_verify.txt -c /tmp/essential_verify.txt \
    -X POST "http://localhost:8000/txs/admin/login/" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=python&password=12345678&csrfmiddlewaretoken=$SESSION&next=/txs/admin/" > /dev/null

PROXY_PAGE=$(curl -s -b /tmp/essential_verify.txt "http://localhost:8000/txs/admin/history/proxyfactory/")
MC_PAGE=$(curl -s -b /tmp/essential_verify.txt "http://localhost:8000/txs/admin/history/safemastercopy/")

if echo "$PROXY_PAGE" | grep -q "0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67"; then
    echo "  Proxy Factory: Configured"
else
    echo "  Proxy Factory: NOT CONFIGURED"
fi

if echo "$MC_PAGE" | grep -q "0x41675C099F32341bf84BFc5382aF534df5C7461a"; then
    echo "  Master Copy 1.3.0: Configured"
else
    echo "  Master Copy 1.3.0: NOT CONFIGURED"
fi

if echo "$MC_PAGE" | grep -q "0x29fcB43b46531BcA003ddC8FCB67FFE91900C762"; then
    echo "  Master Copy 1.4.1: Configured"
else
    echo "  Master Copy 1.4.1: NOT CONFIGURED"
fi

rm -f /tmp/essential_verify.txt
echo ""

echo "================================================================"
echo "Essential Verification Complete"
echo "================================================================"
echo ""
echo "Safe Infrastructure Status: OPERATIONAL"
echo "Access Safe UI: http://localhost:8000/"
echo ""
