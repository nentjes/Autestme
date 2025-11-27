//f204fdf80c8afceebbc98b3f782dc6bb50f0153431b1d075395ba4dcb0dfec82

import Foundation
import BigInt
import web3swift
import Web3Core
import SwiftUI

// @MainActor zorgt dat updates veilig naar de UI gaan
@MainActor
class Web3Manager: ObservableObject {
    static let shared = Web3Manager()
    
    // --- 1. CONFIGURATIE ---
    private let rpcURL = "https://rpc-amoy.polygon.technology"
    private let chainID = BigUInt(80002) // Chain ID voor Polygon Amoy
    
    // JOUW CONTRACT ADRES
    private let contractAddressString = "0xbe00447a89f5bb9e09fd49acf3cfb4dc3f076a26"
    
    // !!! BELANGRIJK: PLAK HIERONDER JE PRIVATE KEY OPNIEUW !!!
    private let privateKey = "f204fdf80c8afceebbc98b3f782dc6bb50f0153431b1d075395ba4dcb0dfec82"
    
    // --- 2. STATUS ---
    @Published var statusMessage: String = "Klaar om te verbinden"
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false
    
    // --- 3. DE HANDLEIDING (ABI) ---
    private let minimalABI = """
    [
        {
            "constant": false,
            "inputs": [
                {"name": "_to", "type": "address"},
                {"name": "_value", "type": "uint256"}
            ],
            "name": "transfer",
            "outputs": [{"name": "", "type": "bool"}],
            "type": "function"
        }
    ]
    """
    
    private init() {}
    
    // --- 4. FUNCTIES ---
    
    func connect() async {
        self.isLoading = true
        self.statusMessage = "Verbinding testen..."
        
        if privateKey.contains("PLAK_HIER") || privateKey.isEmpty {
            self.statusMessage = "❌ Vul eerst je Private Key in Web3Manager.swift!"
            self.isLoading = false
            return
        }
        
        do {
            let _ = try await getWeb3()
            self.isConnected = true
            self.statusMessage = "✅ Verbonden met Polygon Amoy!"
            self.isLoading = false
        } catch {
            self.statusMessage = "❌ Fout: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    func rewardPlayer(amount: Int) async {
        if privateKey.contains("PLAK_HIER") {
            self.statusMessage = "❌ Geen Private Key geconfigureerd"
            return
        }
        
        self.isLoading = true
        self.statusMessage = "Munten overmaken (\(amount))..."
        
        do {
            let web3 = try await getWeb3()
            
            // 1. Het contract laden
            guard let contractAddress = EthereumAddress(contractAddressString) else {
                throw Web3Error.inputError(desc: "Ongeldig contract adres")
            }
            
            guard let contract = web3.contract(minimalABI, at: contractAddress, abiVersion: 2) else {
                throw Web3Error.inputError(desc: "Kon contract niet laden")
            }
            
            // 2. Transactie voorbereiden
            let myAddress = web3.provider.url.scheme == "http" ? EthereumAddress("0x0000000000000000000000000000000000000000")! : walletAddress(from: privateKey)!

            let amountBigInt = BigUInt(amount) * BigUInt(10).power(18)
            let parameters: [Any] = [myAddress, amountBigInt]
            
            // FIX: Geen opties vooraf, we gebruiken de standaard operatie
            guard let writeOperation = contract.createWriteOperation("transfer", parameters: parameters) else {
                throw Web3Error.inputError(desc: "Functie 'transfer' niet gevonden in contract")
            }
            
            // DE OPLOSSING: We stellen de afzender direct in op de transactie-eigenschap
            // Dit vervangt het gedoe met TransactionOptions
            writeOperation.transaction.from = myAddress
            
            // 3. Transactie versturen
            let transaction = try await writeOperation.writeToChain(password: "")
            
            self.statusMessage = "✅ \(amount) AC overgemaakt! Hash: \(transaction.hash.prefix(6))..."
            self.isLoading = false
            print("Transactie hash: \(transaction.hash)")
            
        } catch {
            print("Web3 Fout: \(error)")
            self.statusMessage = "❌ Transactie mislukt: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    // --- HELPER FUNCTIES ---
    
    private func getWeb3() async throws -> Web3 {
        guard let url = URL(string: rpcURL) else { throw Web3Error.inputError(desc: "Ongeldige RPC URL") }
        let provider = try await Web3HttpProvider(url: url, network: .Custom(networkID: chainID))
        let web3 = Web3(provider: provider)
        
        guard let keyData = Data.fromHex(privateKey) else {
            throw Web3Error.inputError(desc: "Ongeldige Private Key Hex")
        }
        
        let keystore = try! EthereumKeystoreV3(privateKey: keyData, password: "")!
        let keystoreManager = KeystoreManager([keystore])
        web3.addKeystoreManager(keystoreManager)
        
        return web3
    }
    
    private func walletAddress(from privateKeyHex: String) -> EthereumAddress? {
        guard let data = Data.fromHex(privateKeyHex) else { return nil }
        let keystore = try? EthereumKeystoreV3(privateKey: data, password: "")
        return keystore?.addresses?.first
    }
}
