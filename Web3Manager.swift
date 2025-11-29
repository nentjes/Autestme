import Foundation
import BigInt
import web3swift
import Web3Core
import SwiftUI

// @MainActor ensures updates are sent safely to the UI
@MainActor
class Web3Manager: ObservableObject {
    static let shared = Web3Manager()
    
    // --- 1. CONFIGURATION ---
    private let rpcURL = "https://polygon-amoy-bor-rpc.publicnode.com"
    private let chainID = BigUInt(80002) // Chain ID for Polygon Amoy
    
    // We halen de gevoelige data uit Secrets.swift
    private let contractAddressString = Secrets.contractAddress
    
    // De app fungeert als de 'Game Treasury' (De Bank)
    private let privateKey = Secrets.privateKeyGameTreasury
    
    // --- 2. STATUS ---
    @Published var statusMessage: String = "Klaar om te verbinden"
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false
    
    // OPGELOST: Deze variabele wordt gevuld door StartScreen
    @Published var recipientAddress: String = "" // Dit is de variabele die gevuld wordt!

    // Logboek voor UI display
    @Published var debugLog: String = ""
    
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
        },
        {
            "constant": true,
            "inputs": [{"name": "_owner", "type": "address"}],
            "name": "balanceOf",
            "outputs": [{"name": "balance", "type": "uint256"}],
            "type": "function"
        }
    ]
    """
    
    private init() {}
    
    // HULPFUNCTIE: Log naar console EN naar de app
    private func log(_ message: String) {
        print(message)
        debugLog += message + "\n"
    }
    
    // --- 4. FUNCTIES ---
    
    func connect() async {
        self.isLoading = true
        self.statusMessage = "Diagnose draaien..."
        self.debugLog = "--- START DIAGNOSE ---\n"
        
        // Checken of Secrets zijn gevuld
        if privateKey.contains("PASTE") || privateKey.isEmpty {
            let msg = "❌ Configureer Secrets.swift eerst!"
            self.statusMessage = msg
            log(msg)
            self.isLoading = false
            return
        }
        
        await runDiagnostics()
        
        do {
            let _ = try await getWeb3()
            self.isConnected = true
            self.statusMessage = "✅ Verbonden als Game Schatkist"
            self.isLoading = false
        } catch {
            let msg = "❌ Fout: \(error.localizedDescription)"
            self.statusMessage = msg
            log(msg)
            self.isLoading = false
        }
    }
    
    // --- 5. ROBUUSTE DIAGNOSE FUNCTIE ---
    func runDiagnostics() async {
        log("\n🕵️‍♂️ --- START DIAGNOSE ---")
        
        guard let myAddress = walletAddress(from: privateKey) else {
            log("❌ FOUT: Ongeldige Private Key.")
            return
        }
        
        log("🆔 AFZENDER (Game Schatkist): \(myAddress.address)")
        
        do {
            let web3 = try await getWeb3()
            
            // 1. Check POL Saldo (Benzine)
            let polBalance = try await web3.eth.getBalance(for: myAddress)
            let polDouble = Double(polBalance.description) ?? 0.0
            let polString = String(format: "%.4f", polDouble / 1e18)
            log("⛽️ GAS SALDO: \(polString) POL")
            
            if polBalance == 0 {
                log("⚠️ WAARSCHUWING: Schatkist heeft 0 POL (geen benzine)!")
            }
            
            // 2. Check AUT Saldo (Tokens)
            if let contractAddress = EthereumAddress(contractAddressString),
               let contract = web3.contract(minimalABI, at: contractAddress, abiVersion: 2) {
                
                log("📜 CONTRACT: \(contractAddress.address)")
                
                let parameters: [Any] = [myAddress]
                
                if let readOp = contract.createReadOperation("balanceOf", parameters: parameters) {
                    readOp.transaction.from = myAddress
                    do {
                        let response = try await readOp.callContractMethod()
                        var balance: BigUInt?
                        if let b = response["balance"] as? BigUInt { balance = b }
                        else if let b = response["0"] as? BigUInt { balance = b }
                        
                        if let bal = balance {
                            let balDouble = Double(bal.description) ?? 0.0
                            let autString = String(format: "%.2f", balDouble / 1e18)
                            log("💰 TOKEN SALDO: \(autString) AUT")
                            
                            if bal == 0 {
                                log("⚠️ WAARSCHUWING: Schatkist is leeg (0 AUT).")
                            }
                        }
                    } catch {
                        log("❌ 'balanceOf' mislukt: \(error.localizedDescription)")
                    }
                }
            }
            
        } catch {
            log("❌ DIAGNOSE FOUT: \(error)")
        }
        log("🕵️‍♂️ --- EINDE DIAGNOSE ---\n")
    }
    
    func rewardPlayer(amount: Int) async {
        if privateKey.isEmpty { return }
        
        self.isLoading = true
        self.statusMessage = "Beloning versturen (\(amount) AUT)..."
        
        // VEREIST: Controleer het dynamisch ingevoerde adres van de speler
        guard recipientAddress.hasPrefix("0x") && recipientAddress.count == 42 else {
            self.statusMessage = "❌ Ongeldig Speler Adres ingevoerd."
            self.isLoading = false
            return
        }

        do {
            let web3 = try await getWeb3()
            guard let contractAddress = EthereumAddress(contractAddressString) else { throw Web3Error.inputError(desc: "Adres fout") }
            guard let contract = web3.contract(minimalABI, at: contractAddress, abiVersion: 2) else { throw Web3Error.inputError(desc: "Contract fout") }
            
            // AFZENDER = Game Treasury (sleutel uit Secrets)
            let myAddress = walletAddress(from: privateKey)!
            
            // ONTVANGER = Het adres dat de speler invoerde in StartScreen
            guard let playerRecipientAddress = EthereumAddress(recipientAddress) else {
                throw Web3Error.inputError(desc: "Ongeldig Ontvanger Adres")
            }
            
            let amountBigInt = BigUInt(amount) * BigUInt(10).power(18)
            let parameters: [Any] = [playerRecipientAddress, amountBigInt] // HIER GEBRUIKEN WE HET DYNAMISCHE ADRES!
            
            log("💸 Versturen: \(amount) AUT")
            log("VAN: \(myAddress.address)")
            log("NAAR: \(playerRecipientAddress.address)")
            
            guard let writeOperation = contract.createWriteOperation("transfer", parameters: parameters) else {
                throw Web3Error.inputError(desc: "Functie niet gevonden")
            }
            
            // 1. Zet Afzender
            writeOperation.transaction.from = myAddress
            writeOperation.transaction.chainID = chainID
            
            // 2. Legacy Gas Settings (Vaste prijs)
            let gasPrice = BigUInt(60_000_000_000) // 60 Gwei
            let policies = Policies(
                gasLimitPolicy: .automatic,
                gasPricePolicy: .manual(gasPrice)
            )
            
            // 3. Verstuur Transactie
            let transaction = try await writeOperation.writeToChain(password: "", policies: policies)
            
            self.statusMessage = "✅ \(amount) AUT overgemaakt! Hash: \(transaction.hash.prefix(6))..."
            log("✅ SUCCES: \(transaction.hash)")
            self.isLoading = false
            
        } catch {
            let msg = "❌ TRANSACTIE FOUT: \(error.localizedDescription)"
            log(msg)
            
            if error.localizedDescription.contains("insufficient funds") {
                self.statusMessage = "❌ Geweigerd: Te weinig POL (Gas)."
            } else if error.localizedDescription.contains("reverted") {
                self.statusMessage = "❌ Geweigerd: Controleer AUT Saldo."
            } else {
                self.statusMessage = msg
            }
            self.isLoading = false
        }
    }
    
    // --- HELPER FUNCTIES ---
    private func getWeb3() async throws -> Web3 {
        guard let url = URL(string: rpcURL) else { throw Web3Error.inputError(desc: "URL Fout") }
        let provider = try await Web3HttpProvider(url: url, network: .Custom(networkID: chainID))
        let web3 = Web3(provider: provider)
        guard let keyData = Data.fromHex(privateKey) else { throw Web3Error.inputError(desc: "Key Fout") }
        let keystore = try! EthereumKeystoreV3(privateKey: keyData, password: "")!
        web3.addKeystoreManager(KeystoreManager([keystore]))
        return web3
    }
    
    private func walletAddress(from privateKeyHex: String) -> EthereumAddress? {
        guard let data = Data.fromHex(privateKeyHex) else { return nil }
        let keystore = try? EthereumKeystoreV3(privateKey: data, password: "")
        return keystore?.addresses?.first
    }
}
