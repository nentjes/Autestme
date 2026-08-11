# Autestme reward-claim relayer

Cloud Functions that hold the game-treasury private key and sign/broadcast
AUT reward payouts on the app's behalf, so the key never has to live in the
iOS client (see `/root/.claude/plans/delegated-noodling-steele.md` in the
session that built this, or `../CLAUDE.md`, for the full background).

## One-time setup (you, not the AI agent — this needs your real credentials)

1. **Install the Firebase CLI** if you don't have it: `npm install -g firebase-tools`, then `firebase login`.
2. **Set the project ID** in `../.firebaserc` (replace `REPLACE_WITH_YOUR_FIREBASE_PROJECT_ID`).
3. **Enable the Blaze (pay-as-you-go) plan** for the project in the Firebase Console — Cloud Functions require it. Cost for this workload (a handful of calls per game) is expected to be pennies/month.
4. **Generate a brand-new treasury wallet.** Do NOT reuse the current `privateKeyGameTreasury` — it has already shipped inside App Store binaries and must be treated as burned regardless of this change. Sweep any remaining AUT/POL from the old treasury address to the new one; this also fail-closes any already-installed old app versions that still try to sign client-side, since their sends will simply revert against an empty wallet.
5. **Store the new key in Secret Manager:**
   ```bash
   firebase functions:secrets:set TREASURY_PRIVATE_KEY
   # paste the new treasury private key when prompted (no 0x prefix or with, ethers accepts both)
   ```
6. **Set the public config params** (contract address, RPC URL). These are `defineString` params (see `src/blockchain.ts`) — the CLI prompts for them interactively on first `firebase deploy`, or set them ahead of time non-interactively via `functions/.env.<project-id>`:
   ```
   POLYGON_RPC_URL=https://polygon-bor-rpc.publicnode.com
   AUT_CONTRACT_ADDRESS=0x3a0DCDFf06f9a0Ad20f212224a5162F6fc0e344c
   ```
7. **Fund the new treasury wallet** with enough POL for gas and enough AUT for ~60-90 days of expected payouts (see `src/config.ts` for the daily caps that bound this).
8. **Register App Check.** In the Firebase Console → App Check, register the iOS app for **App Attest** (requires the app's real bundle ID/Team ID). In Xcode, add the `com.apple.developer.devicecheck.appattest-environment` entitlement. The iOS-side provider setup is in `AutestmeApp.swift`.

## Deploy

```bash
npm --prefix functions install
firebase deploy --only functions,firestore:rules,firestore:indexes
```

## Local development / testing (safe — no real funds, no real key)

```bash
cd functions
npm install
npm test              # vitest unit tests, mocked ethers signer — no network calls
npm run serve          # starts the Functions + Firestore emulator
```

For emulator runs that need a *disposable* signer (never the real treasury
key), create `functions/.secret.local` (gitignored):
```
TREASURY_PRIVATE_KEY=<any throwaway Amoy-testnet-only key, never mainnet funds>
```

## Operational notes

- **Limits** live in `src/config.ts`: 26 AUT max per claim (the real per-round maximum — see comment), 130 AUT/wallet/day, 130 AUT/device/day, 5,000 AUT/day network-wide circuit breaker. Tune based on real usage; there is nothing else enforcing these besides this file.
- **Claims stuck in `pending`** (function crashed mid-broadcast) are picked up every 5 minutes by `reconcileStuckClaims` and marked `sent` (if a confirmed tx is found) or `failed` for manual review. Fase 1 does **not** auto-refund a player's daily allowance on a failed broadcast — check `rewardClaims` documents with `status: "failed"` periodically (Firestore Console or a small admin script) and re-credit manually if the failure wasn't the player's fault.
- **Alerting** is not wired up yet — recommended follow-up: a Cloud Logging metric + alert on `reconcileStuckClaims: flagged for manual review` and on the global daily cap being hit, plus a low-balance alert on the treasury's POL/AUT balance.
