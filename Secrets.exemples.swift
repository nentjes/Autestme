// Secrets.example.swift
// THIS FILE IS SAFE TO COMMIT TO GITHUB
// Instructions for new developers:
// 1. Copy this file and rename it to 'Secrets.swift'
// 2. Fill in your own test keys
// 3. Ensure 'Secrets.swift' is listed in your .gitignore

import Foundation

struct SecretsExample {
    // 1. The address of the Token Contract
    static let contractAddress = "PASTE_TOKEN_ADDRESS_HERE"
    
    // 2. The Private Keys (The keys to the vaults)
    static let privateKeyAutestme = "PASTE_KEY_HERE"
    static let privateKeyFounder = "PASTE_KEY_HERE"
    static let privateKeyDAOTreasury = "PASTE_KEY_HERE"
    static let privateKeyGameTreasury = "PASTE_KEY_HERE" // <-- This will be the 'Bank'
    
    // 3. The addresses of the Wallets (To send funds to)
    static let AutestmeWalletAddress = "PASTE_ADDRESS_HERE" // Fixed spelling here
    static let FounderWalletAddress = "PASTE_ADDRESS_HERE" // <-- This will be the 'Player'
    static let DAOTreasuryWalletAddress = "PASTE_ADDRESS_HERE"
    static let GameTreasuryWalletAddress = "PASTE_ADDRESS_HERE"
}
