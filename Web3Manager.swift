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
    private let rpcURL = "https://polygon-amoy-bor-rpc.publicnode.com"
    private let chainID = BigUInt(80002) // Chain ID voor Polygon Amoy
    
    // We halen de gevoelige data weer uit Secrets.swift
    private let contractAddressString = Secrets.contractAddress
    private let privateKey = Secrets.privateKey
    
    // --- 2. STATUS ---
    @Published var statusMessage: String = "Klaar om te verbinden"
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false
    
    // NIEUW: Een logboek dat de UI kan lezen
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
        self.debugLog = "--- START DIAGNOSE ---\n" // Reset log bij nieuwe poging
        
        // Checken of Secrets.swift wel gevuld is (geen standaard placeholders)
        if privateKey.contains("PLAK_HIER") || privateKey.isEmpty {
            let msg = "❌ Vul je Private Key in Secrets.swift!"
            self.statusMessage = msg
            log(msg)
            self.isLoading = false
            return
        }
        
        if contractAddressString.contains("PLAK_HIER") {
            let msg = "❌ Vul het Token Adres in Secrets.swift!"
            self.statusMessage = msg
            log(msg)
            self.isLoading = false
            return
        }
        
        await runDiagnostics()
        
        do {
            let _ = try await getWeb3()
            self.isConnected = true
            self.statusMessage = "✅ Diagnose voltooid. Zie Log."
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
        log("\n🕵️‍♂️ --- START DIAGNOSE AUTESTME ---")
        
        guard let myAddress = walletAddress(from: privateKey) else {
            log("❌ FOUT: Kan geen adres maken van Private Key.")
            return
        }
        
        log("🆔 MIJN WALLET ADRES: \(myAddress.address)")
        
        do {
            let web3 = try await getWeb3()
            
            // 1. Check POL Saldo (Benzine)
            let polBalance = try await web3.eth.getBalance(for: myAddress)
            let polDouble = Double(polBalance.description) ?? 0.0
            let polString = String(format: "%.4f", polDouble / 1_000_000_000_000_000_000.0)
            log("⛽️ POL SALDO: \(polString) POL")
            
            if polBalance == 0 {
                log("⚠️ WAARSCHUWING: Je hebt 0 POL. Je kunt geen transacties betalen!")
            } else {
                log("✅ Benzine aanwezig.")
            }
            
            // 2. Check Contract & AUT Saldo
            if let contractAddress = EthereumAddress(contractAddressString),
               let contract = web3.contract(minimalABI, at: contractAddress, abiVersion: 2) {
                
                log("📜 CONTRACT ADRES: \(contractAddress.address)")
                
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
                            let autString = String(format: "%.2f", balDouble / 1_000_000_000_000_000_000.0)
                            log("💰 AUT SALDO: \(autString) AUT")
                            
                            if bal == 0 {
                                log("⚠️ WAARSCHUWING: Je hebt 0 AUT. Vul deze wallet!")
                            } else {
                                log("✅ Munten aanwezig.")
                            }
                        } else {
                            log("⚠️ Kon saldo wel ophalen, maar niet lezen.")
                        }
                    } catch {
                        log("❌ FOUT bij 'balanceOf': \(error.localizedDescription)")
                    }
                }
            }
            
        } catch {
            log("❌ DIAGNOSE ERROR: \(error)")
        }
        log("🕵️‍♂️ --- EINDE DIAGNOSE ---\n")
    }
    
    func rewardPlayer(amount: Int) async {
        // Dubbelcheck de keys
        if privateKey.contains("PLAK_HIER") { return }
        
        self.isLoading = true
        self.statusMessage = "Munten overmaken (\(amount))..."
        
        do {
            let web3 = try await getWeb3()
            guard let contractAddress = EthereumAddress(contractAddressString) else { throw Web3Error.inputError(desc: "Adres fout") }
            guard let contract = web3.contract(minimalABI, at: contractAddress, abiVersion: 2) else { throw Web3Error.inputError(desc: "Contract fout") }
            
            let myAddress = web3.provider.url.scheme == "http" ? EthereumAddress("0x0000000000000000000000000000000000000000")! : walletAddress(from: privateKey)!
            let amountBigInt = BigUInt(amount) * BigUInt(10).power(18)
            let parameters: [Any] = [myAddress, amountBigInt]
            
            guard let writeOperation = contract.createWriteOperation("transfer", parameters: parameters) else {
                throw Web3Error.inputError(desc: "Functie niet gevonden")
            }
            
            // 1. Zet afzender
            writeOperation.transaction.from = myAddress
            writeOperation.transaction.chainID = chainID
            
            // 2. CONFIGURATIE MET POLICIES (LEGACY MODE)
            // We gebruiken een vaste gasprijs in plaats van EIP-1559 tips
            // Dit is stabieler op testnetten zoals Amoy.
            
            let gasPrice = BigUInt(60_000_000_000) // 60 Gwei (Ruim boven minimum)
            
            let policies = Policies(
                gasLimitPolicy: .automatic,
                gasPricePolicy: .manual(gasPrice)
            )
            
            // 3. Verstuur transactie met de legacy policies
            let transaction = try await writeOperation.writeToChain(password: "", policies: policies)
            
            self.statusMessage = "✅ \(amount) AC overgemaakt! Hash: \(transaction.hash.prefix(6))..."
            log("✅ TRANS ACTION SUCCESS: Hash \(transaction.hash)")
            self.isLoading = false
            
        } catch {
            // Betere foutmeldingen
            let msg = "❌ TRANSACTIE FOUT: \(error.localizedDescription)"
            log(msg)
            
            if error.localizedDescription.contains("insufficient funds") {
                self.statusMessage = "❌ Te weinig POL op deze wallet."
            } else if error.localizedDescription.contains("reverted") {
                self.statusMessage = "❌ Geweigerd: Waarschijnlijk te weinig AUT."
            } else {
                self.statusMessage = msg // Toon de echte fout, niet "Check Policy"
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
