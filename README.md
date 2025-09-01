## evm-deposit-wallets

### About

This repository explores different approaches for implementing customer deposit wallets in EVM-based systems. Traditional deposit wallet solutions require spinning up individual addresses for each customer, then performing multiple transactions when deposits occur: first sending gas to the wallet if needed, then withdrawing funds to a parent wallet. This multi-step process introduces multiple points of failure and incurs additional gas costs from moving ETH around.

Three approaches were explored in this repository:

1. **Basic Proxy Wallet Approach** (`ProxyWallet.sol`): Deploy minimal proxy contracts as deposit wallets with simple owner-controlled withdrawal functions for ERC-20 tokens and ETH. While this provides basic functionality, it still requires pre-funding wallets with gas for withdrawals and involves multiple transactions.

2. **Enhanced Proxy Wallet Approach** (`ProxyWalletWithExec.sol`): An enhanced version of the proxy wallet that adds arbitrary call execution capabilities, allowing for more complex operations from deposit wallets. However, it still suffers from the same gas funding and multi-transaction limitations as the basic approach.

3. **ERC-7702 Approach** (`BatchCallAndSponsor.sol`): The final and optimal solution that leverages ERC-7702 to enable sweeping deposit wallets in a single transaction. This approach eliminates the need for multiple transactions by allowing wallets to be authorized once and then swept directly, avoiding the gas overhead of moving ETH to deposit wallets while only incurring a small overhead for the initial authorization.

The ERC-7702 approach ultimately proved superior as it provides the most reliable and gas-efficient deposit wallet system, requiring only a single transaction to sweep funds without needing to manage gas distribution to individual wallets.

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
BATCH_SPONSOR_AND_CALL=""
COMBINE_CALLS=""
SETTLEMENT_ADDRESS=""
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
