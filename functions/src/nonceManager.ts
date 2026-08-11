import { FieldValue } from "firebase-admin/firestore";
import type { Firestore, Transaction } from "firebase-admin/firestore";
import type { JsonRpcProvider } from "ethers";

const NONCE_DOC = "treasuryState/nonce";

/**
 * Atomically reserves the next nonce for the treasury wallet inside the
 * caller's Firestore transaction, preventing two concurrent claims from
 * broadcasting with the same nonce. If no nonce has been tracked yet, it
 * seeds itself from the chain's pending transaction count — safe to do
 * inside a transaction retry since eth_getTransactionCount is a read-only,
 * side-effect-free RPC call.
 */
export async function reserveNonce(
  txn: Transaction,
  db: Firestore,
  provider: JsonRpcProvider,
  treasuryAddress: string,
  now: Date,
): Promise<number> {
  const ref = db.doc(NONCE_DOC);
  const snap = await txn.get(ref);

  const nonce = snap.exists
    ? (snap.data()?.nextNonce as number)
    : await provider.getTransactionCount(treasuryAddress, "pending");

  txn.set(ref, { nextNonce: nonce + 1, updatedAt: now.toISOString() }, { merge: true });
  return nonce;
}

/**
 * Force-resyncs the tracked nonce from the chain, discarding our local
 * counter. Use after a broadcast fails with a nonce-related RPC error, or
 * from the scheduled reconciler if claims are stuck.
 */
export async function resyncNonce(
  db: Firestore,
  provider: JsonRpcProvider,
  treasuryAddress: string,
): Promise<number> {
  const onChainNonce = await provider.getTransactionCount(treasuryAddress, "pending");
  await db.doc(NONCE_DOC).set(
    { nextNonce: onChainNonce, updatedAt: FieldValue.serverTimestamp(), resyncedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return onChainNonce;
}
