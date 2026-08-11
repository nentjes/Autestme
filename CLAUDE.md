# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Autestme is a "Develop-to-Earn" (D2E) iOS + watchOS platform for neurodiverse talent. The app is a memory training game where users earn cryptocurrency ($AUT tokens) on the Polygon Mainnet for high scores, and compete on a global Firebase leaderboard.

## Build Commands

```bash
# Build the app
xcodebuild -project Autestme1.xcodeproj -scheme Autestme1 -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild -project Autestme1.xcodeproj -scheme Autestme1 -destination 'platform=iOS Simulator,name=iPhone 16' test

# Run only UI tests
xcodebuild -project Autestme1.xcodeproj -scheme Autestme1 -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:Autestme1UITests test
```

## Setup Requirements

1. Xcode 15+, iOS 16.4+ deployment target, Swift 5.9
2. Copy `Secrets.exemples.swift` to `Secrets.swift` and fill in the public contract/wallet addresses. **No private key belongs in this file, or anywhere in the app** — see `functions/README.md` for treasury key setup.
3. Download `GoogleService-Info.plist` from Firebase Console → project Autestme → iOS app, and add it to the `Autestme1` target in Xcode
4. Open `Autestme1.xcodeproj` — SPM dependencies (web3swift, BigInt, FirebaseCore, FirebaseFirestore, FirebaseFunctions, FirebaseAppCheck) resolve automatically
5. Register the app for App Check (App Attest) in the Firebase Console — required for `Web3Manager.rewardPlayer` to succeed against a deployed backend; see `functions/README.md` step 8
6. Deploy the `functions/` Cloud Functions project (see `functions/README.md`) — the app has no reward flow to test against without it

## Architecture

**SwiftUI with Observable Objects** — Pure SwiftUI app, no UIKit.

### Key Components

- **`AutestmeApp.swift`** → `NavigationViewWrapper` → `StartScreen`: App entry point, initialises Firebase via `FirebaseApp.configure()`
- **`GameLogic`** (ObservableObject): Game state, configuration, scoring, high score persistence via UserDefaults
- **`GameTimer`** (ObservableObject): Dual timer system (countdown + shape display intervals)
- **`Web3Manager`** (ObservableObject, Singleton): Requests reward payouts via the `claimReward` Firebase Cloud Function (`/functions`) and reads read-only balances via web3swift on Polygon Mainnet. Holds no private key — signing happens exclusively server-side.
- **`FirebaseManager`** (ObservableObject, Singleton, @MainActor): Firestore operations — `submitScore()` and `fetchLeaderboard()`; uses fire-and-forget pattern for score submission
- **`LeaderboardView`** (SwiftUI View): Displays top 50 global scores with gold/silver/bronze colours; pull-to-refresh

### Navigation Flow

StartScreen (config + leaderboard link) → GameContainerView (gameplay) → EndScreen (results, rewards, score submission) → StartScreen

### Game Types

Three modes via `GameVersion` enum: `.shapes`, `.letters`, `.numbers`

### Blockchain Integration

- `Web3Manager.shared` requests reward payouts and reads read-only treasury/contract balances; it never holds a private key
- Rewards triggered on EndScreen for correct answers (1 AUT per correct answer, capped at 26 per claim — see `functions/src/config.ts`)
- The treasury private key lives only in Google Secret Manager, loaded exclusively by the `claimReward` Cloud Function (`functions/src/claimReward.ts`), which validates the request (checksummed address, per-call/per-wallet/per-device/global daily caps, idempotent per `gameId`), signs, and broadcasts the transfer
- Gas price: fetched dynamically from network + 30 Gwei tip for Polygon EIP-1559 minimum (mirrored client- and server-side)
- `Web3Manager` persists an unclaimed reward locally and retries it via `retryPendingClaimIfAny` on next launch if the request never confirmed — safe to retry because the server dedupes by `gameId`
- All blockchain calls are async/await
- See `/functions/README.md` for the full backend architecture, deploy steps, and operational limits

### Firebase / Leaderboard Integration

- `FirebaseManager.shared` singleton handles all Firestore operations
- Score submitted automatically on EndScreen when "Show results" is tapped
- Leaderboard collection: `leaderboard` — documents contain: `playerName`, `score`, `gameType`, `deviceID`, `timestamp`, `gameTime`, `numberOfItems`
- `GoogleService-Info.plist` is git-ignored — must be obtained from Firebase Console
- Firestore security rules: only `create` allowed (no update/delete); score must be 0–100; gameType must be shapes/letters/numbers

### Apple Watch

- Watch app target: `AutestmeWatch Watch App`
- Source files in `AutestmeWatch Watch App/` folder
- App icon: `AutestmeWatch Watch App/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (1024×1024)

## Localization

Five languages: English (en), Dutch (nl), Spanish (es-US), Chinese (zh-Hans), Hindi (hi). Uses `NSLocalizedString` with keys in `Localizable.strings` files.

## File Conventions

- **Secrets.swift**: Git-ignored, contains only the public token contract address and public wallet addresses. Never contains a private key.
- **GoogleService-Info.plist**: Git-ignored, contains Firebase API keys
- **`functions/`**: Cloud Functions backend (Node/TypeScript) that signs and broadcasts reward payouts server-side. The treasury private key lives only in Google Secret Manager, bound via `functions/src/blockchain.ts`'s `defineSecret` — never in this repo. See `functions/README.md`.
- **Audio files**: MP3s for each shape/letter sound stored in app bundle
- Code comments mix English and Dutch
