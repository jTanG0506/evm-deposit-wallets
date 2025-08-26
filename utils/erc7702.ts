import { ethers } from "ethers";

export const BATCH_ABI = [
  "function nonce() view returns (uint256)",
  "function execute((address,uint256,bytes)[],bytes) external payable",
];

export const getDelegationAddress = async (
  provider: ethers.Provider,
  address: string
): Promise<string | null> => {
  try {
    const code = await provider.getCode(address);
    if (code === "0x") {
      return null;
    }

    // Check if it's an EIP-7702 delegation (starts with 0xef0100)
    if (code.startsWith("0xef0100")) {
      // Extract the delegated address (remove 0xef0100 prefix)
      const delegatedAddress = "0x" + code.slice(8);

      console.log(`✅ Delegation found for ${address}`);
      console.log(`📍 Delegated to: ${delegatedAddress}`);
      console.log(`📝 Full delegation code: ${code}`);

      return delegatedAddress;
    } else {
      console.log(`❓ Address has code but not EIP-7702 delegation: ${code}`);
      return null;
    }
  } catch (error) {
    console.error(`❌ Error getting delegation address: ${error}`);
    return null;
  }
};

export const createAuthorization = async (
  signer: ethers.Signer,
  target: string,
  nonce?: number
) => {
  const auth = signer.authorize({
    address: target,
    nonce,
  });

  return auth;
};
