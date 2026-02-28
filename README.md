# Autestme: Neurodiverse Talent Ecosystem

Autestme is a pioneering "Develop-to-Earn" (D2E) platform designed to empower neurodiverse programming talent. By combining cognitive training games with blockchain technology, we are building a sovereign digital economy where talent is recognized, verified, and directly rewarded.

## 🚀 Vision

Our mission is to unlock the immense potential of programmers with autism. Autestme provides a platform where:

- **Talent is Verified:** Contributions are tracked on-chain.
- **Work is Rewarded:** Developers earn AutestCoin ($AUT) for every approved pull request.
- **Community Governs:** The ecosystem is steered by a DAO of token holders.

## 🎮 The App

The iOS + Apple Watch application is the first touchpoint. It is a memory training game that demonstrates the core loop:

- **Play:** Users train their memory with shapes, numbers, and letters.
- **Earn:** High scores trigger real-time blockchain transactions on the Polygon Mainnet.
- **Compete:** Scores are saved to a global leaderboard visible to all players.
- **Verify:** Rewards are transparently viewable on-chain via Polygonscan.

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| Platform | iOS 16.4+ + watchOS (Apple Watch) |
| Language | Swift 5.9 (SwiftUI) |
| Blockchain | Polygon Mainnet (EIP-1559, ERC-20) |
| Database | Firebase Firestore (global leaderboard) |
| SPM Libraries | web3swift, BigInt, FirebaseCore, FirebaseFirestore |
| Smart Contracts | Solidity (ERC-20) |

## 📦 Installation for Developers

### Prerequisites

- Xcode 15+
- A Polygon Mainnet compatible wallet (MetaMask)
- Access to the project's Firebase Console (ask a maintainer)

### Setup

**1. Clone the repository:**
```bash
git clone https://github.com/nentjes/Autestme.git
cd Autestme
```

**2. Configure blockchain secrets:**

Copy `Secrets.exemples.swift` and rename to `Secrets.swift` (already in `.gitignore`):
```swift
struct Secrets {
    static let contractAddress = "YOUR_TOKEN_CONTRACT_ADDRESS"
    static let privateKeyGameTreasury = "YOUR_TREASURY_WALLET_PRIVATE_KEY"
}
```

**3. Configure Firebase:**

- Go to [console.firebase.google.com](https://console.firebase.google.com) → project **Autestme**
- Go to Project Settings → iOS app → download `GoogleService-Info.plist`
- Drag the file into Xcode under the `Autestme1` target (already in `.gitignore`)

**4. Install dependencies:**

Open `Autestme1.xcodeproj` in Xcode. SPM resolves automatically:
- `web3swift` + `BigInt` (blockchain)
- `FirebaseCore` + `FirebaseFirestore` (leaderboard)

If packages are missing: *File → Add Package Dependencies* → `https://github.com/firebase/firebase-ios-sdk` → select `FirebaseCore` + `FirebaseFirestore`.

**5. Run:**

Select scheme `Autestme` + an iPhone Simulator and press `Cmd+R`.

## 🔐 Security

The following files are git-ignored and must never be committed:

| File | Why |
|---|---|
| `Secrets.swift` | Contains treasury wallet private key |
| `GoogleService-Info.plist` | Contains Firebase API keys |

## 📄 Documentation

For a deep dive into the project's philosophy, economy, and architecture:

- **Whitepaper:** The vision, D2E model, and DAO structure.
- **Technical Documentation:** System architecture, smart contracts, and security.

---

*Autestme — Coding a more inclusive future.*
