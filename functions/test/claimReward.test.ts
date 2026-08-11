import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";
import "./setup.js";

const mockSendRewardTransfer = vi.fn();

vi.mock("../src/blockchain.js", () => ({
  getProvider: () => ({ getTransactionCount: async () => 0 }),
  getTreasuryWallet: () => ({ address: "0xTreasuryAddress0000000000000000000001" }),
  sendRewardTransfer: (...args: unknown[]) => mockSendRewardTransfer(...args),
  treasuryPrivateKey: { value: () => "0xmock" },
}));

const { claimReward } = await import("../src/claimReward.js");

const VALID_ADDRESS = "0x5aAeb6053F3E94C9b9A09f33669435E7Ef1BeAed";

function request(overrides: Record<string, unknown> = {}): CallableRequest {
  return {
    data: {
      recipientAddress: VALID_ADDRESS,
      amount: 5,
      gameId: crypto.randomUUID(),
      deviceId: "device-1",
      ...overrides,
    },
    auth: undefined,
    app: { appId: "test-app" },
    rawRequest: {} as never,
  } as CallableRequest;
}

describe("claimReward", () => {
  beforeEach(() => {
    mockSendRewardTransfer.mockReset();
    mockSendRewardTransfer.mockResolvedValue({ txHash: "0xhash" });
  });

  it("signs and broadcasts a valid claim", async () => {
    const result = await claimReward.run(request());
    expect(result).toEqual({ status: "sent", txHash: "0xhash" });
    expect(mockSendRewardTransfer).toHaveBeenCalledTimes(1);
  });

  it("replays an already-claimed gameId idempotently, without broadcasting again", async () => {
    const gameId = crypto.randomUUID();
    const first = await claimReward.run(request({ gameId }));
    const second = await claimReward.run(request({ gameId }));

    expect(first).toEqual(second);
    expect(mockSendRewardTransfer).toHaveBeenCalledTimes(1);
  });

  it("rejects a claim above the per-call cap before touching the blockchain", async () => {
    await expect(claimReward.run(request({ amount: 27 }))).rejects.toThrow();
    expect(mockSendRewardTransfer).not.toHaveBeenCalled();
  });

  it("rejects a malformed recipient address before touching the blockchain", async () => {
    await expect(claimReward.run(request({ recipientAddress: "not-an-address" }))).rejects.toThrow();
    expect(mockSendRewardTransfer).not.toHaveBeenCalled();
  });

  it("records a failed claim and surfaces an error when broadcasting throws", async () => {
    mockSendRewardTransfer.mockRejectedValueOnce(new Error("RPC unreachable"));
    await expect(claimReward.run(request())).rejects.toThrow();
  });
});
