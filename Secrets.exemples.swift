// Secrets.example.swift
// THIS FILE IS SAFE TO COMMIT TO GITHUB
// Instructions for new developers:
// 1. Copy this file and rename it to 'Secrets.swift'
// 2. Fill in your own public addresses (see functions/README.md for the
//    treasury PRIVATE key, which lives only in Google Secret Manager and
//    must never be added here or anywhere else in the client)
// 3. Ensure 'Secrets.swift' is listed in your .gitignore

import Foundation

// No private key belongs in this file, or anywhere else in the app. Every
// reward payout is signed server-side by the claimReward Cloud Function
// (see /functions), which is the only place the treasury key is ever
// loaded — from Google Secret Manager, never from source or the client.
struct SecretsExample {
    // 1. The address of the Token Contract (public info)
    static let contractAddress = "PASTE_TOKEN_ADDRESS_HERE"

    // 2. The addresses of the Wallets (public info — used to display/default
    //    recipients, never to sign anything from this app)
    static let AutestmeWalletAddress = "PASTE_ADDRESS_HERE"
    static let FounderWalletAddress = "PASTE_ADDRESS_HERE"
    static let DAOTreasuryWalletAddress = "PASTE_ADDRESS_HERE"
    static let GameTreasuryWalletAddress = "PASTE_ADDRESS_HERE"
}
