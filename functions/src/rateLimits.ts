import { FieldValue } from "firebase-admin/firestore";
import type { Firestore, Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import {
  MAX_AUT_GLOBAL_PER_DAY,
  MAX_AUT_PER_DEVICE_PER_DAY,
  MAX_AUT_PER_WALLET_PER_DAY,
} from "./config.js";

/** UTC calendar-day key, e.g. "20260811". Caps reset at UTC midnight. */
export function dayKey(now: Date): string {
  return now.toISOString().slice(0, 10).replace(/-/g, "");
}

interface RateLimitParams {
  db: Firestore;
  txn: Transaction;
  walletAddress: string;
  deviceId: string;
  amount: number;
  now: Date;
}

interface RateLimitDocRefs {
  walletRef: FirebaseFirestore.DocumentReference;
  deviceRef: FirebaseFirestore.DocumentReference;
  globalRef: FirebaseFirestore.DocumentReference;
}

function docRefs(db: Firestore, walletAddress: string, deviceId: string, now: Date): RateLimitDocRefs {
  const key = dayKey(now);
  return {
    walletRef: db.collection("rateLimits").doc(`wallet_${walletAddress}_${key}`),
    deviceRef: db.collection("rateLimits").doc(`device_${deviceId}_${key}`),
    globalRef: db.collection("rateLimits").doc(`global_${key}`),
  };
}

/**
 * Reads today's wallet/device/global counters (must happen before any writes
 * in the enclosing Firestore transaction) and returns their current totals.
 */
export async function readRateLimitCounters(
  params: Pick<RateLimitParams, "db" | "txn" | "walletAddress" | "deviceId" | "now">,
): Promise<{ refs: RateLimitDocRefs; walletTotal: number; deviceTotal: number; globalTotal: number }> {
  const { db, txn, walletAddress, deviceId, now } = params;
  const refs = docRefs(db, walletAddress, deviceId, now);

  const [walletSnap, deviceSnap, globalSnap] = await Promise.all([
    txn.get(refs.walletRef),
    txn.get(refs.deviceRef),
    txn.get(refs.globalRef),
  ]);

  return {
    refs,
    walletTotal: (walletSnap.data()?.totalAut as number | undefined) ?? 0,
    deviceTotal: (deviceSnap.data()?.totalAut as number | undefined) ?? 0,
    globalTotal: (globalSnap.data()?.totalAut as number | undefined) ?? 0,
  };
}

/**
 * Throws HttpsError if applying `amount` would breach any cap. Call this
 * strictly after readRateLimitCounters (and before any txn.set/update calls)
 * within the same transaction.
 */
export function assertWithinRateLimits(
  amount: number,
  counters: { walletTotal: number; deviceTotal: number; globalTotal: number },
): void {
  if (counters.walletTotal + amount > MAX_AUT_PER_WALLET_PER_DAY) {
    throw new HttpsError(
      "resource-exhausted",
      "Daily reward limit reached for this wallet. Try again tomorrow.",
    );
  }
  if (counters.deviceTotal + amount > MAX_AUT_PER_DEVICE_PER_DAY) {
    throw new HttpsError(
      "resource-exhausted",
      "Daily reward limit reached for this device. Try again tomorrow.",
    );
  }
  if (counters.globalTotal + amount > MAX_AUT_GLOBAL_PER_DAY) {
    throw new HttpsError(
      "resource-exhausted",
      "Autestme has hit its network-wide daily reward cap. Try again tomorrow.",
    );
  }
}

/** Increments the three daily counters. Write-only — call after all reads. */
export function reserveRateLimits(
  txn: Transaction,
  refs: RateLimitDocRefs,
  amount: number,
  now: Date,
): void {
  for (const ref of [refs.walletRef, refs.deviceRef, refs.globalRef]) {
    txn.set(
      ref,
      { totalAut: FieldValue.increment(amount), updatedAt: now.toISOString() },
      { merge: true },
    );
  }
}
