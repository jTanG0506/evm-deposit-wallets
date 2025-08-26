import { ethers } from "ethers";

export const ERC20_Interface = new ethers.Interface([
  "function balanceOf(address owner) view returns (uint256)",
  "function transfer(address to, uint256 amount) returns (bool)",
]);

export const getERC20Balance = async (
  tokenAddress: string,
  address: string,
  provider: ethers.Provider
): Promise<bigint> => {
  const tokenContract = new ethers.Contract(
    tokenAddress,
    ERC20_Interface,
    provider
  );

  try {
    const balance = await tokenContract.balanceOf(address);
    return balance;
  } catch (error) {
    console.error(
      `Error getting ${tokenAddress} balance for ${address}:`,
      error
    );
    return 0n;
  }
};
