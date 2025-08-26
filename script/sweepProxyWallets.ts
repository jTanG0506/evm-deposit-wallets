import { ethers } from "ethers";

import { loadConfig } from "../utils/config";
import { ERC20_Interface, getERC20Balance } from "../utils/erc20";
import {
  BATCH_ABI,
  createAuthorization,
  getDelegationAddress,
} from "../utils/erc7702";

const main = async () => {
  const config = loadConfig();

  const { provider, combineContract } = config;

  const proxyWallets = config.proxyWallets.map(
    (t) => new ethers.Wallet(t.privateKey, provider)
  );
  const tokenAddresses = config.tokenAddresses;

  const authorizations = [];
  for (let i = 0; i < proxyWallets.length; ++i) {
    const w = proxyWallets[i];
    const delegationAddress = await getDelegationAddress(provider, w.address);

    const needsAuth =
      !delegationAddress ||
      delegationAddress.toLowerCase() !== config.imp.toLowerCase();

    if (!needsAuth) {
      continue;
    }

    const auth = await createAuthorization(w, config.imp);
    authorizations.push(auth);
  }

  const targets: string[] = [];
  const values: bigint[] = [];
  const data: string[] = [];
  for (let i = 0; i < proxyWallets.length; ++i) {
    const w = proxyWallets[i];

    const calls: Array<{ to: string; value: bigint; data: string }> = [];
    for (let j = 0; j < tokenAddresses.length; ++j) {
      const tokenAddress = tokenAddresses[j];
      const balance = await getERC20Balance(tokenAddress, w.address, provider);

      if (balance > 0n) {
        calls.push({
          to: tokenAddress,
          value: 0n,
          data: ERC20_Interface.encodeFunctionData("transfer", [
            config.settlementAddress,
            balance,
          ]),
        });
      }
    }

    if (calls.length === 0) {
      continue;
    }

    let encodedCalls = "0x";
    const positionalCalls: Array<[string, bigint, string]> = [];
    for (let k = 0; k < calls.length; ++k) {
      const { to, value, data } = calls[k];
      encodedCalls += ethers
        .solidityPacked(["address", "uint256", "bytes"], [to, value, data])
        .slice(2);

      positionalCalls.push([to, value, data]);
    }

    let nonce = 0;
    try {
      const proxyImplForDigest = new ethers.Contract(
        w.address,
        BATCH_ABI,
        provider
      );
      nonce = await proxyImplForDigest.nonce();
    } catch {}

    const digest = ethers.keccak256(
      ethers.solidityPacked(["uint256", "bytes"], [nonce, encodedCalls])
    );
    const signature = await w.signMessage(ethers.getBytes(digest));

    const batchInterface = new ethers.Interface(BATCH_ABI);
    const encoded = batchInterface.encodeFunctionData("execute", [
      positionalCalls,
      signature,
    ]);

    targets.push(w.address);
    values.push(0n);
    data.push(encoded);
  }

  const tx = await combineContract.bulkExecute(
    targets,
    values,
    data,
    authorizations.length > 0
      ? {
          type: 4,
          authorizationList: authorizations,
        }
      : {}
  );

  console.log("✅ TX Hash:", tx.hash);
  await tx.wait();
};

main();
