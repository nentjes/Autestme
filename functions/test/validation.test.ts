import { HttpsError } from "firebase-functions/v2/https";
import { describe, expect, it } from "vitest";
import { MAX_AUT_PER_CLAIM } from "../src/config.js";
import { validateClaimRequest } from "../src/validation.js";

// EIP-55 test vector — a genuinely, correctly checksummed address.
const VALID_ADDRESS = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed";

const BASE = {
  recipientAddress: VALID_ADDRESS,
  amount: 5,
  gameId: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  deviceId: "device-123",
};

describe("validateClaimRequest", () => {
  it("accepts a well-formed request and returns the checksummed address", () => {
    const result = validateClaimRequest(BASE);
    expect(result.recipientAddress).toBe(VALID_ADDRESS);
    expect(result.amount).toBe(5);
  });

  it("normalizes a lowercase address to its checksummed form", () => {
    const result = validateClaimRequest({
      ...BASE,
      recipientAddress: VALID_ADDRESS.toLowerCase(),
    });
    expect(result.recipientAddress).toBe(VALID_ADDRESS);
  });

  it("rejects an address with a bad checksum (wrong letter case)", () => {
    const badChecksum = `${VALID_ADDRESS.slice(0, -1)}D`; // flips the correct trailing "d"
    expect(() => validateClaimRequest({ ...BASE, recipientAddress: badChecksum })).toThrow(
      HttpsError,
    );
  });

  it("rejects a malformed address", () => {
    expect(() =>
      validateClaimRequest({ ...BASE, recipientAddress: "not-an-address" }),
    ).toThrow(HttpsError);
  });

  it(`rejects an amount above the per-claim cap of ${MAX_AUT_PER_CLAIM}`, () => {
    expect(() => validateClaimRequest({ ...BASE, amount: MAX_AUT_PER_CLAIM + 1 })).toThrow(
      HttpsError,
    );
  });

  it("accepts an amount exactly at the cap", () => {
    expect(() => validateClaimRequest({ ...BASE, amount: MAX_AUT_PER_CLAIM })).not.toThrow();
  });

  it("rejects a non-integer amount", () => {
    expect(() => validateClaimRequest({ ...BASE, amount: 5.5 })).toThrow(HttpsError);
  });

  it("rejects a zero or negative amount", () => {
    expect(() => validateClaimRequest({ ...BASE, amount: 0 })).toThrow(HttpsError);
    expect(() => validateClaimRequest({ ...BASE, amount: -3 })).toThrow(HttpsError);
  });

  it("rejects a non-UUID gameId", () => {
    expect(() => validateClaimRequest({ ...BASE, gameId: "not-a-uuid" })).toThrow(HttpsError);
  });

  it("rejects a request missing deviceId", () => {
    const { deviceId: _deviceId, ...rest } = BASE;
    expect(() => validateClaimRequest(rest)).toThrow(HttpsError);
  });
});
