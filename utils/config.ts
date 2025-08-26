import { ethers, isAddress } from "ethers";

export const loadConfig = () => {
  const rpcUrl = process.env.SEPOLIA_RPC_URL;
  const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY;
  const tokenAddressesStr = process.env.ERC20_TOKENS;
  const proxyWalletPrivateKeys = process.env.PRIVATE_KEYS;
  const imp = process.env.BATCH_SPONSOR_AND_CALL;
  const combineCallsAddress = process.env.COMBINE_CALLS;
  const settlementAddress = process.env.SETTLEMENT_ADDRESS;

  let deployer: ethers.Wallet;
  let combineContract: ethers.Contract;

  if (!rpcUrl) {
    throw new Error("MISSING_ENV: RPC_URL");
  }

  const provider = new ethers.JsonRpcProvider(rpcUrl);

  if (!deployerPrivateKey) {
    throw new Error("MISSING_ENV: DEPLOYER_PRIVATE_KEY");
  }

  try {
    deployer = new ethers.Wallet(deployerPrivateKey, provider);
  } catch (error) {
    throw new Error("INVALID_PRIVATE_KEY: DEPLOYER_PRIVATE_KEY");
  }

  if (!tokenAddressesStr) {
    throw new Error("MISSING_ENV: ERC20_TOKENS");
  }

  if (!proxyWalletPrivateKeys) {
    throw new Error("MISSING_ENV: PRIVATE_KEYS");
  }

  if (!imp) {
    throw new Error("MISSING_ENV: BATCH_SPONSOR_AND_CALL");
  }

  if (!isAddress(imp)) {
    throw new Error("INVALID_ADDRESS: BATCH_SPONSOR_AND_CALL");
  }

  if (!combineCallsAddress) {
    throw new Error("MISSING_ENV: COMBINE_CALLS");
  }

  if (!isAddress(combineCallsAddress)) {
    throw new Error("INVALID_ADDRESS: COMBINE_CALLS");
  }

  combineContract = new ethers.Contract(
    combineCallsAddress,
    [
      "function bulkExecute(address[] targets, uint256[] values, bytes[] data) external returns (bytes[] returnData)",
    ],
    deployer
  );

  if (!settlementAddress) {
    throw new Error("MISSING_ENV: SETTLEMENT_ADDRESS");
  }

  if (!isAddress(settlementAddress)) {
    throw new Error("INVALID_ADDRESS: SETTLEMENT_ADDRESS");
  }

  const proxyWallets: ethers.Wallet[] = [];
  for (const key of proxyWalletPrivateKeys.split(",")) {
    try {
      proxyWallets.push(new ethers.Wallet(key, provider));
    } catch (error) {
      console.error(`Error loading proxy wallet: ${error}`);
    }
  }

  if (proxyWallets.length === 0) {
    throw new Error("NO_PROXY_WALLETS");
  }

  const tokenAddresses: string[] = [];
  for (const address of tokenAddressesStr.split(",")) {
    try {
      if (!isAddress(address)) {
        continue;
      }

      tokenAddresses.push(address);
    } catch (error) {
      console.error(`Error loading token address: ${error}`);
    }
  }

  if (tokenAddresses.length === 0) {
    throw new Error("NO_TOKEN_ADDRESSES");
  }

  return {
    provider,
    deployer,
    combineContract,
    tokenAddresses,
    proxyWallets,
    imp,
    settlementAddress,
  };
};
