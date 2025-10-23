#!/bin/bash

set -e

# Check if L2 RPC is accessible (port 8547 is fixed for L2)
echo "==> $(date +%H:%M:%S) ==> Checking L2 RPC endpoint accessibility..."
L2_RPC_PORT=8547

if ! curl -s -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
     http://localhost:$L2_RPC_PORT > /dev/null 2>&1; then
    echo "Error: L2 RPC not accessible at localhost:$L2_RPC_PORT"
    echo "Make sure the L2 rollup (l2-nethermind-execution-client) is running"
    echo "You can start it from: /home/ubuntu/surge/simple-surge-node/"
    exit 1
fi

# Set L2 RPC endpoint for Safe infrastructure
export RPC_NODE_URL="http://host.docker.internal:$L2_RPC_PORT"

L2_CHAIN_ID=$(curl -s -X POST -H "Content-Type: application/json" \
     --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
     http://localhost:$L2_RPC_PORT | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

echo "==> $(date +%H:%M:%S) ==> L2 RPC found: Chain ID = $L2_CHAIN_ID ($(printf "%d" $L2_CHAIN_ID))"
echo "==> $(date +%H:%M:%S) ==> Using RPC_NODE_URL=$RPC_NODE_URL"

echo "==> $(date +%H:%M:%S) ==> Starting up environment containers..."
docker compose pull \
  && docker compose down -v \
  && docker compose up -d \
  && echo "==> $(date +%H:%M:%S) ==> Creating super-user for Safe Config Service... (may take a while)" \
  && docker compose exec cfg-web python src/manage.py createsuperuser \
  && echo "==> $(date +%H:%M:%S) ==> Creating super-user for Safe Transaction Service... (may take a while)" \
  && docker compose exec txs-web python manage.py createsuperuser || exit

echo "==> $(date +%H:%M:%S) ==> All set! You may want to add a ChainInfo into the Config service. Please use the link below to fill its data: http://localhost:8000/cfg/admin/chains/chain/add/"
