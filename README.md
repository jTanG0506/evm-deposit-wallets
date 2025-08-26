## evm-deposit-wallets

### Setup

Setup `.env` as follows:

- `ERC20_TOKENS` should be comma separated token addresses
- `ERC20_AMOUNTS` should be comma separate token amounts
- `PRIVATE_KEYS` should be comma separated private keys (same length as `ERC20_AMOUNTS`)

```
SEPOLIA_RPC_URL=""
ETHERSCAN_API_KEY=""
DEPLOYER_PRIVATE_KEY=""
ERC20_TOKENS=""
ERC20_AMOUNTS=""
PRIVATE_KEYS=""
```

### Scripts

### Deploy ERC-20 tokens

```shell
forge script script/DeployERC20.s.sol:DeployTestERC20 --sig "deploy(string,string)" "USDC" "USDC" --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Mint ERC-20 tokens

```shell
forge script script/MintERC20.s.sol:MintTestERC20 --sig "mint()" --rpc-url $SEPOLIA_RPC_URL --broadcast
```

### Deploy ERC-7702 Implementation and CombineCalls

```shell
forge script script/Deploy.s.sol:Deploy --sig "deploy()" --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```
