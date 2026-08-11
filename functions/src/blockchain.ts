import { Contract, JsonRpcProvider, Wallet, parseUnits } from "ethers";
import { defineSecret, defineString } from "firebase-functions/params";
import { ERC20_TRANSFER_ABI, PRIORITY_FEE_GWEI, TOKEN_DECIMALS } from "./config.js";

/** Treasury signing key. Bound from Google Secret Manager, never in source. */
export const treasuryPrivateKey = defineSecret("TREASURY_PRIVATE_KEY");

/** Public config — not secret, but kept out of source so it can rotate without a redeploy of code. */
export const polygonRpcUrl = defineString("POLYGON_RPC_URL", {
  default: "https://polygon-bor-rpc.publicnode.com",
});
export const autContractAddress = defineString("AUT_CONTRACT_ADDRESS");

export function getProvider(): JsonRpcProvider {
  return new JsonRpcProvider(polygonRpcUrl.value());
}

export function getTreasuryWallet(provider: JsonRpcProvider): Wallet {
  return new Wallet(treasuryPrivateKey.value(), provider);
}

interface SendRewardParams {
  wallet: Wallet;
  provider: JsonRpcProvider;
  recipient: string;
  amount: number;
  nonce: number;
}

/**
 * Signs and broadcasts an ERC-20 transfer of `amount` AUT to `recipient`,
 * mirroring the gas strategy previously used client-side in
 * Web3Manager.swift: network gas price plus a 30 Gwei priority tip
 * (Polygon's EIP-1559 minimum). Returns immediately after broadcast —
 * callers persist the pending txHash and do not wait for confirmation.
 */
export async function sendRewardTransfer(params: SendRewardParams): Promise<{ txHash: string }> {
  const { wallet, provider, recipient, amount, nonce } = params;

  const contract = new Contract(autContractAddress.value(), ERC20_TRANSFER_ABI, wallet);
  const amountWei = parseUnits(amount.toString(), TOKEN_DECIMALS);

  const baseFee = await provider.send("eth_gasPrice", []);
  const priorityFee = PRIORITY_FEE_GWEI * 1_000_000_000n;
  const maxFeePerGas = BigInt(baseFee) + priorityFee;

  const tx = await contract.transfer(recipient, amountWei, {
    nonce,
    maxFeePerGas,
    maxPriorityFeePerGas: priorityFee,
  });

  return { txHash: tx.hash as string };
}
