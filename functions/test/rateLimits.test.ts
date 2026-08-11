import { getFirestore } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";
import "./setup.js";
import {
  MAX_AUT_GLOBAL_PER_DAY,
  MAX_AUT_PER_DEVICE_PER_DAY,
  MAX_AUT_PER_WALLET_PER_DAY,
} from "../src/config.js";
import {
  assertWithinRateLimits,
  dayKey,
  readRateLimitCounters,
  reserveRateLimits,
} from "../src/rateLimits.js";

describe("dayKey", () => {
  it("formats a UTC date as YYYYMMDD", () => {
    expect(dayKey(new Date("2026-08-11T23:59:00Z"))).toBe("20260811");
  });
});

describe("assertWithinRateLimits", () => {
  const zero = { walletTotal: 0, deviceTotal: 0, globalTotal: 0 };

  it("allows a claim within all caps", () => {
    expect(() => assertWithinRateLimits(10, zero)).not.toThrow();
  });

  it("rejects when the wallet daily cap would be exceeded", () => {
    expect(() =>
      assertWithinRateLimits(1, { ...zero, walletTotal: MAX_AUT_PER_WALLET_PER_DAY }),
    ).toThrow(HttpsError);
  });

  it("rejects when the device daily cap would be exceeded", () => {
    expect(() =>
      assertWithinRateLimits(1, { ...zero, deviceTotal: MAX_AUT_PER_DEVICE_PER_DAY }),
    ).toThrow(HttpsError);
  });

  it("rejects when the global daily cap would be exceeded", () => {
    expect(() =>
      assertWithinRateLimits(1, { ...zero, globalTotal: MAX_AUT_GLOBAL_PER_DAY }),
    ).toThrow(HttpsError);
  });
});

describe("readRateLimitCounters + reserveRateLimits (Firestore emulator)", () => {
  it("accumulates totals across repeated same-day reservations for a wallet/device", async () => {
    const db = getFirestore();
    const wallet = `0xTestWallet${Date.now()}`;
    const device = `device-${Date.now()}`;
    const now = new Date();

    for (const amount of [5, 8]) {
      await db.runTransaction(async (txn) => {
        const counters = await readRateLimitCounters({
          db,
          txn,
          walletAddress: wallet,
          deviceId: device,
          now,
        });
        assertWithinRateLimits(amount, counters);
        reserveRateLimits(txn, counters.refs, amount, now);
      });
    }

    const final = await db.runTransaction((txn) =>
      readRateLimitCounters({ db, txn, walletAddress: wallet, deviceId: device, now }),
    );
    expect(final.walletTotal).toBe(13);
    expect(final.deviceTotal).toBe(13);
  });

  it("keeps wallet totals independent across different wallets sharing a device", async () => {
    const db = getFirestore();
    const device = `shared-device-${Date.now()}`;
    const walletA = `0xWalletA${Date.now()}`;
    const walletB = `0xWalletB${Date.now()}`;
    const now = new Date();

    await db.runTransaction(async (txn) => {
      const counters = await readRateLimitCounters({ db, txn, walletAddress: walletA, deviceId: device, now });
      reserveRateLimits(txn, counters.refs, 9, now);
    });

    const walletBCounters = await db.runTransaction((txn) =>
      readRateLimitCounters({ db, txn, walletAddress: walletB, deviceId: device, now }),
    );
    expect(walletBCounters.walletTotal).toBe(0);
    expect(walletBCounters.deviceTotal).toBe(9); // device cap is shared across wallets on purpose
  });
});
