import { getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import {
  getProvider,
  getTreasuryWallet,
  sendRewardTransfer,
  treasuryPrivateKey,
} from "./blockchain.js";
import { reserveNonce, resyncNonce } from "./nonceManager.js";
import {
  assertWithinRateLimits,
  readRateLimitCounters,
  reserveRateLimits,
} from "./rateLimits.js";
import { validateClaimRequest } from "./validation.js";

interface ClaimDoc {
  status: "pending" | "sent" | "failed";
  recipientAddress: string;
  amount: number;
  deviceId: string;
  nonce: number;
  txHash?: string;
  error?: string;
  createdAt: string;
  updatedAt?: string;
}

/**
 * Callable relayer that signs and broadcasts a player's AUT reward on the
 * treasury's behalf. This is the only place the treasury private key is
 * ever loaded — it never leaves this function's runtime memory. Requires a
 * valid App Check token, but that only proves the caller is a genuine app
 * instance; the amount/rate-limit checks below are the actual defense,
 * since the game score itself is still client-reported (fase 1).
 */
export const claimReward = onCall(
  {
    enforceAppCheck: true,
    secrets: [treasuryPrivateKey],
    region: "us-central1",
  },
  async (request) => {
    const validated = validateClaimRequest(request.data);
    const db = getFirestore();
    const provider = getProvider();
    const now = new Date();

    const claimRef = db.collection("rewardClaims").doc(validated.gameId);

    const reservation = await db.runTransaction(async (txn) => {
      const existing = await txn.get(claimRef);
      if (existing.exists) {
        // Idempotent replay of a claim we've already seen (client retry).
        return { alreadyClaimed: true as const, doc: existing.data() as ClaimDoc };
      }

      const counters = await readRateLimitCounters({
        db,
        txn,
        walletAddress: validated.recipientAddress,
        deviceId: validated.deviceId,
        now,
      });
      assertWithinRateLimits(validated.amount, counters);

      const treasuryAddress = getTreasuryWallet(provider).address;
      const nonce = await reserveNonce(txn, db, provider, treasuryAddress, now);

      reserveRateLimits(txn, counters.refs, validated.amount, now);

      const doc: ClaimDoc = {
        status: "pending",
        recipientAddress: validated.recipientAddress,
        amount: validated.amount,
        deviceId: validated.deviceId,
        nonce,
        createdAt: now.toISOString(),
      };
      txn.set(claimRef, doc);

      return { alreadyClaimed: false as const, doc };
    });

    if (reservation.alreadyClaimed) {
      logger.info("claimReward: idempotent replay", { gameId: validated.gameId, status: reservation.doc.status });
      if (reservation.doc.status === "failed") {
        throw new HttpsError("internal", reservation.doc.error ?? "Previous claim attempt failed.");
      }
      return { status: reservation.doc.status, txHash: reservation.doc.txHash ?? null };
    }

    const wallet = getTreasuryWallet(provider);

    try {
      const { txHash } = await sendRewardTransfer({
        wallet,
        provider,
        recipient: validated.recipientAddress,
        amount: validated.amount,
        nonce: reservation.doc.nonce,
      });

      await claimRef.set(
        { status: "sent", txHash, updatedAt: new Date().toISOString() },
        { merge: true },
      );

      logger.info("claimReward: broadcast succeeded", { gameId: validated.gameId, txHash });
      return { status: "sent", txHash };
    } catch (err) {
      const message = err instanceof Error ? err.message : "Unknown broadcast error";
      logger.error("claimReward: broadcast failed", { gameId: validated.gameId, error: message });

      if (/nonce/i.test(message)) {
        await resyncNonce(db, provider, wallet.address).catch((resyncErr) =>
          logger.error("claimReward: nonce resync failed", { error: String(resyncErr) }),
        );
      }

      await claimRef.set(
        { status: "failed", error: message, updatedAt: new Date().toISOString() },
        { merge: true },
      );

      throw new HttpsError(
        "internal",
        "Could not send your reward right now. Your claim was recorded and will be reviewed.",
      );
    }
  },
);
