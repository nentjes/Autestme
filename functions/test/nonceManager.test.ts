import { getFirestore } from "firebase-admin/firestore";
import type { JsonRpcProvider } from "ethers";
import { describe, expect, it } from "vitest";
import "./setup.js";
import { reserveNonce } from "../src/nonceManager.js";

function fakeProvider(startingNonce: number): JsonRpcProvider {
  return {
    getTransactionCount: async () => startingNonce,
  } as unknown as JsonRpcProvider;
}

describe("reserveNonce", () => {
  it("seeds from the chain's pending nonce on first use", async () => {
    const db = getFirestore();
    // reserveNonce always targets the fixed doc "treasuryState/nonce"; isolate
    // this test by clearing it first.
    await db.doc("treasuryState/nonce").delete();

    const nonce = await db.runTransaction((txn) =>
      reserveNonce(txn, db, fakeProvider(42), "0xTreasuryAddress", new Date()),
    );
    expect(nonce).toBe(42);
  });

  it("increments by one on each subsequent reservation", async () => {
    const db = getFirestore();
    await db.doc("treasuryState/nonce").delete();

    const first = await db.runTransaction((txn) =>
      reserveNonce(txn, db, fakeProvider(100), "0xTreasuryAddress", new Date()),
    );
    const second = await db.runTransaction((txn) =>
      reserveNonce(txn, db, fakeProvider(100), "0xTreasuryAddress", new Date()),
    );
    expect(first).toBe(100);
    expect(second).toBe(101);
  });

  it("never hands out the same nonce twice under concurrent reservations", async () => {
    const db = getFirestore();
    await db.doc("treasuryState/nonce").delete();

    const CONCURRENCY = 10;
    const nonces = await Promise.all(
      Array.from({ length: CONCURRENCY }, () =>
        db.runTransaction((txn) => reserveNonce(txn, db, fakeProvider(0), "0xTreasuryAddress", new Date())),
      ),
    );

    expect(new Set(nonces).size).toBe(CONCURRENCY);
  });
});
