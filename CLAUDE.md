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
2. Copy `Secrets.exemples.swift` to `Secrets.swift` and fill in blockchain keys
3. Download `GoogleService-Info.plist` from Firebase Console → project Autestme → iOS app, and add it to the `Autestme1` target in Xcode
4. Open `Autestme1.xcodeproj` — SPM dependencies (web3swift, BigInt, FirebaseCore, FirebaseFirestore) resolve automatically

## Architecture

**SwiftUI with Observable Objects** — Pure SwiftUI app, no UIKit.

### Key Components

- **`AutestmeApp.swift`** → `NavigationViewWrapper` → `StartScreen`: App entry point, initialises Firebase via `FirebaseApp.configure()`
- **`GameLogic`** (ObservableObject): Game state, configuration, scoring, high score persistence via UserDefaults
- **`GameTimer`** (ObservableObject): Dual timer system (countdown + shape display intervals)
- **`Web3Manager`** (ObservableObject, Singleton): Blockchain operations via web3swift on Polygon Mainnet; uses EIP-1559 with dynamic gas pricing (fetches network price + 30 Gwei tip)
- **`FirebaseManager`** (ObservableObject, Singleton, @MainActor): Firestore operations — `submitScore()` and `fetchLeaderboard()`; uses fire-and-forget pattern for score submission
- **`LeaderboardView`** (SwiftUI View): Displays top 50 global scores with gold/silver/bronze colours; pull-to-refresh

### Navigation Flow

StartScreen (config + leaderboard link) → GameContainerView (gameplay) → EndScreen (results, rewards, score submission) → StartScreen

### Game Types

Three modes via `GameVersion` enum: `.shapes`, `.letters`, `.numbers`

### Blockchain Integration

- `Web3Manager.shared` singleton handles all crypto operations
- Rewards triggered on EndScreen for correct answers (1 AUT per correct answer)
- Treasury wallet (configured in Secrets.swift) sends tokens to player wallet
- Gas price: fetched dynamically from network (`web3.eth.gasPrice()`) + 30 Gwei tip for Polygon EIP-1559 minimum
- All blockchain calls are async/await

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

- **Secrets.swift**: Git-ignored, contains contract address and treasury private key
- **GoogleService-Info.plist**: Git-ignored, contains Firebase API keys
- **Audio files**: MP3s for each shape/letter sound stored in app bundle
- Code comments mix English and Dutch
