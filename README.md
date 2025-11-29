# Autestme
Autestme: Neurodiverse Talent Ecosystem

Autestme is a pioneering "Develop-to-Earn" (D2E) platform designed to empower neurodiverse programming talent. By combining cognitive training games with blockchain technology, we are building a sovereign digital economy where talent is recognized, verified, and directly rewarded.

🚀 Vision

Our mission is to unlock the immense potential of programmers with autism. Autestme provides a platform where:

Talent is Verified: Contributions are tracked on-chain.

Work is Rewarded: Developers earn AutestCoin ($AUT) for every approved pull request.

Community Governs: The ecosystem is steered by a DAO of token holders.

🎮 The App (Alpha)

The current iOS application serves as the first touchpoint. It is a memory training game that demonstrates the core loop:

Play: Users train their memory with shapes, numbers, and letters.

Earn: High scores trigger real-time blockchain transactions on the Polygon network.

Verify: Rewards are transparently viewable on-chain.

🛠 Tech Stack

Platform: iOS 16.4+

Language: Swift 5.9 (SwiftUI)

Blockchain: Polygon Amoy Testnet (Proof of Stake)

Libraries:

web3swift (Blockchain interaction)

BigInt (Precise calculations)

Smart Contracts: Solidity (ERC-20, Chainlink Functions)

📦 Installation for Developers

Join us in building the future of neurodiverse employment!

Prerequisites

Xcode 15+

A Polygon Amoy compatible wallet (MetaMask)

Setup

Clone the Repository:

git clone [https://github.com/nentjes/Autestme.git](https://github.com/nentjes/Autestme.git)
cd Autestme



Configure Secrets:

Duplicate Secrets.example.swift and rename it to Secrets.swift.

Important: Add Secrets.swift to your .gitignore to protect your keys.

Fill in your testnet keys:

struct Secrets {
    static let contractAddress = "YOUR_TOKEN_CONTRACT_ADDRESS"
    static let privateKey = "YOUR_TEST_WALLET_PRIVATE_KEY"
}



Install Dependencies:
Open Autestme.xcodeproj in Xcode. The Swift Package Manager should automatically resolve dependencies (web3swift, BigInt).

Run:
Select an iOS Simulator (e.g., iPhone 16) and press Cmd + R.

📄 Documentation

For a deep dive into the project's philosophy, economy, and architecture, please refer to our documentation:

Whitepaper: The vision, D2E model, and DAO structure.

Technical Documentation: System architecture, smart contracts, and security.

Autestme - Coding a more inclusive future.
