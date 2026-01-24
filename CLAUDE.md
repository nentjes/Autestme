# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Autestme is a "Develop-to-Earn" (D2E) iOS platform for neurodiverse talent. The app is a memory training game where users earn cryptocurrency ($AUT tokens) on the Polygon network for high scores.

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
3. Open `Autestme1.xcodeproj` - SPM dependencies (web3swift, BigInt) resolve automatically

## Architecture

**SwiftUI with Observable Objects** - Pure SwiftUI app, no UIKit.

### Key Components

- **`AutestmeApp.swift`** → `NavigationViewWrapper` → `StartScreen`: App entry point
- **`GameLogic`** (ObservableObject): Game state, configuration, scoring, high score persistence via UserDefaults
- **`GameTimer`** (ObservableObject): Dual timer system (countdown + shape display intervals)
- **`Web3Manager`** (ObservableObject, Singleton): Blockchain operations via web3swift on Polygon Mainnet

### Navigation Flow

StartScreen (config) → GameContainerView (gameplay) → EndScreen (results & rewards) → StartScreen

### Game Types

Three modes via `GameVersion` enum: `.shapes`, `.letters`, `.numbers`

### Blockchain Integration

- `Web3Manager.shared` singleton handles all crypto operations
- Rewards triggered on EndScreen for correct answers (1 AUT per correct)
- Treasury wallet (configured in Secrets.swift) sends tokens to player wallet
- All blockchain calls are async/await

## Localization

Five languages: English (en), Dutch (nl), Spanish (es-US), Chinese (zh-Hans), Hindi (hi). Uses `NSLocalizedString` with keys in `Localizable.strings` files.

## File Conventions

- **Secrets.swift**: Git-ignored, contains contract addresses and private keys
- **Audio files**: MP3s for each shape/letter sound stored in app bundle
- Code comments mix English and Dutch
