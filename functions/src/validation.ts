import { getAddress } from "ethers";
import { HttpsError } from "firebase-functions/v2/https";
import { z } from "zod";
import { MAX_AUT_PER_CLAIM } from "./config.js";

export const ClaimRewardRequestSchema = z.object({
  recipientAddress: z.string().min(1),
  amount: z.number().int().positive(),
  gameId: z.string().uuid(),
  deviceId: z.string().min(1).max(128),
});

export type ClaimRewardRequest = z.infer<typeof ClaimRewardRequestSchema>;

export interface ValidatedClaim {
  recipientAddress: string; // EIP-55 checksummed
  amount: number;
  gameId: string;
  deviceId: string;
}

/**
 * Parses and authoritatively validates a claim request. Throws HttpsError
 * (safe to surface to the client) on any violation. This is the server's
 * only real defense while the client's reported score is still trusted —
 * it must never be skipped or weakened.
 */
export function validateClaimRequest(data: unknown): ValidatedClaim {
  const parsed = ClaimRewardRequestSchema.safeParse(data);
  if (!parsed.success) {
    throw new HttpsError("invalid-argument", "Malformed claim request.");
  }

  let checksummed: string;
  try {
    checksummed = getAddress(parsed.data.recipientAddress);
  } catch {
    throw new HttpsError(
      "invalid-argument",
      "recipientAddress is not a valid checksummed EVM address.",
    );
  }

  if (parsed.data.amount > MAX_AUT_PER_CLAIM) {
    throw new HttpsError(
      "invalid-argument",
      `amount exceeds the maximum of ${MAX_AUT_PER_CLAIM} AUT per claim.`,
    );
  }

  return {
    recipientAddress: checksummed,
    amount: parsed.data.amount,
    gameId: parsed.data.gameId,
    deviceId: parsed.data.deviceId,
  };
}
