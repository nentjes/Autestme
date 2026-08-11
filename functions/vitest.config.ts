import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // Tests share global Firestore documents (treasuryState/nonce,
    // rateLimits/*) against a single running emulator — running test files
    // in parallel worker processes causes cross-file races on that shared
    // state, so keep them sequential.
    fileParallelism: false,
    // The emulator's first gRPC round-trip in a fresh process can be slow;
    // give it headroom beyond vitest's 5s default.
    testTimeout: 20000,
  },
});
