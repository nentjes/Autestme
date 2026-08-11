import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { getProvider, treasuryPrivateKey } from "./blockchain.js";
import { STUCK_CLAIM_TIMEOUT_MS } from "./config.js";

/**
 * Every 5 minutes, finds reward claims stuck in "pending" for longer than
 * STUCK_CLAIM_TIMEOUT_MS — meaning the function crashed or timed out
 * between reserving the claim and recording its final outcome — and
 * resolves what it safely can:
 *  - if a txHash was recorded and it's confirmed on-chain, marks it "sent"
 *  - otherwise flags it "failed" for manual review (fase 1: no
 *    auto-retry/refund; see functions/README.md for the manual process)
 */
export const reconcileStuckClaims = onSchedule(
  { schedule: "every 5 minutes", secrets: [treasuryPrivateKey] },
  async () => {
    const db = getFirestore();
    const provider = getProvider();
    const cutoff = new Date(Date.now() - STUCK_CLAIM_TIMEOUT_MS).toISOString();

    const stuck = await db
      .collection("rewardClaims")
      .where("status", "==", "pending")
      .where("createdAt", "<", cutoff)
      .get();

    if (stuck.empty) {
      return;
    }

    logger.warn("reconcileStuckClaims: found stuck claims", { count: stuck.size });

    for (const doc of stuck.docs) {
      const data = doc.data();
      const now = new Date().toISOString();

      if (data.txHash) {
        const receipt = await provider.getTransactionReceipt(data.txHash).catch(() => null);
        if (receipt && receipt.status === 1) {
          await doc.ref.set({ status: "sent", updatedAt: now }, { merge: true });
          continue;
        }
      }

      await doc.ref.set(
        {
          status: "failed",
          error: "Stuck in pending past timeout; flagged for manual review.",
          updatedAt: now,
        },
        { merge: true },
      );
      logger.error("reconcileStuckClaims: flagged for manual review", { gameId: doc.id });
    }
  },
);
