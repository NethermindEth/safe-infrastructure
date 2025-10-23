# Safe Infrastructure Scripts

Production-ready scripts for deploying and verifying Safe infrastructure on Surge L2.

## Deployment

### 1. Deploy Safe Infrastructure

```bash
./scripts/run_locally.sh
```

This script:
- Validates L2 RPC is accessible at port 8547
- Sets RPC_NODE_URL environment variable
- Pulls latest Docker images
- Cleans volumes and starts all containers
- Creates superusers for Config and Transaction services

**Credentials:**
- Username: python
- Password: 12345678

### 2. Configure Safe for L2

```bash
./scripts/setup-safe-for-l2.sh
```

This script:
- Auto-detects L2 Chain ID from RPC
- Adds L2 chain to Config Service
- Registers Safe contract addresses
- Configures Transaction Service with Proxy Factory and Master Copies

## Verification

### Verify Complete Infrastructure

```bash
./scripts/verify-safe-infrastructure.sh
```

**Recommended for CI/CD testing.**

This comprehensive script verifies:
1. L2 Chain ID detection
2. L2 block production status
3. API endpoint health (Config, Transaction, Gateway)
4. Transaction Service indexing status
5. Safe contract deployments on-chain
6. Transaction Service configuration via admin panel

All checks must pass for infrastructure to be considered operational.

## Requirements

### Minimum Requirements
- Docker and Docker Compose installed
- L2 RPC accessible at http://localhost:8547
- Port 8000 available for nginx reverse proxy

### For L2 Block Production
L2 must be producing blocks for live transaction testing. This requires a proposer bond:

```bash
cd /home/ubuntu/surge/simple-surge-node
SURGE_PROPOSER_WRAPPER=0x35DE3C39FE87df24087c5C8178376Efa586D74B0 \
BOND_AMOUNT=100000000000000000000 \
docker compose -f docker-compose-protocol.yml --profile bond-deposit up
```

## Access Points

After deployment:
- Safe UI: http://localhost:8000/
- Config Admin: http://localhost:8000/cfg/admin/
- Transaction Admin: http://localhost:8000/txs/admin/

## Troubleshooting

### Container Issues
```bash
docker compose logs <service-name>
```

### Database Reset
If you need to switch chains or reset the database:
```bash
docker compose down
sudo rm -rf data/
./scripts/run_locally.sh
```

### L2 Block Production Issues
Check proposer bond balance:
```bash
cast call 0x02F759282b4094b6e61e85dFc1F6B6889aeaa223 \
  "bondBalanceOf(address)" \
  0x35DE3C39FE87df24087c5C8178376Efa586D74B0 \
  --rpc-url http://localhost:32003
```

## Known Limitations

Safe wallet deployment via Proxy Factory currently fails on Surge L2 with a Create2 error. The infrastructure is fully operational for indexing existing Safe wallets, but creating new Safe wallets via the UI will not work until this is resolved.

For detailed deployment history and troubleshooting, see PLAN.md.
