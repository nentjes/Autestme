//f204fdf80c8afceebbc98b3f782dc6bb50f0153431b1d075395ba4dcb0dfec82

import Foundation
import BigInt
import web3swift
import Web3Core
import SwiftUI // Nodig voor @Published

class Web3Manager: ObservableObject {
    static let shared = Web3Manager()
    
    // --- CONFIGURATIE ---
    // Polygon Amoy RPC URL (Testnet)
    private let rpcURL = "https://rpc-amoy.polygon.technology"
    
    // Vul hier later je eigen gegevens in
    private let privateKey = "f204fdf80c8afceebbc98b3f782dc6bb50f0153431b1d075395ba4dcb0dfec82"
    private let contractAddress = "0x1234567890123456789012345678901234567890"
    
    // --- STATUS VARIABELEN ---
    @Published var statusMessage: String = "Klaar om te verbinden"
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false // Deze variabele miste je eerder
    
    private init() {}
    
    // --- FUNCTIES ---
    
    // Functie voor de 'Verbind' knop op het startscherm
    func connect() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.statusMessage = "Verbinding maken met blockchain..."
        }
        
        do {
            // SIMULATIE: Hier komt later de echte check of de private key geldig is
            try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            
            DispatchQueue.main.async {
                self.isConnected = true
                self.statusMessage = "✅ Verbonden met Schatkist!"
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "❌ Verbindingsfout: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // Functie voor het EndScreen om munten uit te keren
    func rewardPlayer(amount: Int) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.statusMessage = "Verbinding maken met schatkist..."
        }
        
        do {
            // SIMULATIE: Hier komt later de echte transactie code
            try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
            
            DispatchQueue.main.async {
                self.statusMessage = "✅ \(amount) AutestCoins verzonden!"
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "❌ Fout: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
