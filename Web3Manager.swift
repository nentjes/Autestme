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
    
    // Fetch sensitive data from Secrets.swift
    private let contractAddressString = Secrets.contractAddress
    
    // AANGEPAST: De app fungeert als de 'Game Treasury' (De Bank)
    // We gebruiken dus de sleutel van de Game Treasury om te ondertekenen.
    // Zorg dat in jouw echte Secrets.swift 'static let privateKeyGameTreasury' bestaat!
    private let privateKey = Secrets.privateKeyGameTreasury
    
    // --- 2. STATUS ---
    @Published var statusMessage: String = "Ready to connect"
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false
    
    // Logbook for UI display
    @Published var debugLog: String = ""
    
    // --- 3. ABI DEFINITION ---
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
    
    // HELPER: Log to console AND app UI
    private func log(_ message: String) {
        print(message)
        debugLog += message + "\n"
    }
    
    // --- 4. FUNCTIONS ---
    
    func connect() async {
        self.isLoading = true
        self.statusMessage = "Running diagnostics..."
        self.debugLog = "--- START DIAGNOSTICS ---\n"
        
        // Check if Secrets are filled
        if privateKey.contains("PASTE") || privateKey.isEmpty {
            let msg = "❌ Configure Secrets.swift first!"
            self.statusMessage = msg
            log(msg)
            self.isLoading = false
            return
        }
        
        await runDiagnostics()
        
        do {
            let _ = try await getWeb3()
            self.isConnected = true
            self.statusMessage = "✅ Connected as Game Treasury"
            self.isLoading = false
        } catch {
            let msg = "❌ Error: \(error.localizedDescription)"
            self.statusMessage = msg
            log(msg)
            self.isLoading = false
        }
    }
    
    // --- 5. ROBUST DIAGNOSTICS FUNCTION ---
    func runDiagnostics() async {
        log("\n🕵️‍♂️ --- START DIAGNOSTICS ---")
        
        guard let myAddress = walletAddress(from: privateKey) else {
            log("❌ ERROR: Invalid Private Key.")
            return
        }
        
        log("🆔 SENDER (Game Treasury): \(myAddress.address)")
        
        do {
            let web3 = try await getWeb3()
            
            // 1. Check POL Balance (Gas)
            let polBalance = try await web3.eth.getBalance(for: myAddress)
            let polDouble = Double(polBalance.description) ?? 0.0
            let polString = String(format: "%.4f", polDouble / 1e18)
            log("⛽️ GAS BALANCE: \(polString) POL")
            
            if polBalance == 0 {
                log("⚠️ WARNING: Treasury has 0 POL for gas!")
            }
            
            // 2. Check AUT Balance (Tokens)
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
                            log("💰 TOKEN BALANCE: \(autString) AUT")
                            
                            if bal == 0 {
                                log("⚠️ WARNING: Treasury is empty (0 AUT).")
                            }
                        }
                    } catch {
                        log("❌ 'balanceOf' failed: \(error.localizedDescription)")
                    }
                }
            }
            
        } catch {
            log("❌ DIAGNOSTICS ERROR: \(error)")
        }
        log("🕵️‍♂️ --- END DIAGNOSTICS ---\n")
    }
    
    func rewardPlayer(amount: Int) async {
        if privateKey.isEmpty { return }
        
        self.isLoading = true
        self.statusMessage = "Rewarding Player (\(amount) AUT)..."
        
        do {
            let web3 = try await getWeb3()
            guard let contractAddress = EthereumAddress(contractAddressString) else { throw Web3Error.inputError(desc: "Address error") }
            guard let contract = web3.contract(minimalABI, at: contractAddress, abiVersion: 2) else { throw Web3Error.inputError(desc: "Contract error") }
            
            // SENDER = Game Treasury (from secrets)
            let myAddress = walletAddress(from: privateKey)!
            
            // RECIPIENT = Founder (as test player)
            // We use the Founder address from Secrets as the destination
            guard let recipientString = Secrets.FounderWalletAddress as String?,
                  let recipientAddress = EthereumAddress(recipientString) else {
                throw Web3Error.inputError(desc: "Invalid Founder Address in Secrets")
            }
            
            let amountBigInt = BigUInt(amount) * BigUInt(10).power(18)
            let parameters: [Any] = [recipientAddress, amountBigInt]
            
            log("💸 Sending \(amount) AUT")
            log("FROM: \(myAddress.address)")
            log("TO:   \(recipientAddress.address)")
            
            guard let writeOperation = contract.createWriteOperation("transfer", parameters: parameters) else {
                throw Web3Error.inputError(desc: "Function not found")
            }
            
            // 1. Set Sender
            writeOperation.transaction.from = myAddress
            writeOperation.transaction.chainID = chainID
            
            // 2. Legacy Gas Settings (Fixed price)
            let gasPrice = BigUInt(60_000_000_000) // 60 Gwei
            let policies = Policies(
                gasLimitPolicy: .automatic,
                gasPricePolicy: .manual(gasPrice)
            )
            
            // 3. Send Transaction
            let transaction = try await writeOperation.writeToChain(password: "", policies: policies)
            
            self.statusMessage = "✅ \(amount) AUT Sent! Hash: \(transaction.hash.prefix(6))..."
            log("✅ SUCCESS: \(transaction.hash)")
            self.isLoading = false
            
        } catch {
            let msg = "❌ TRANSACTION ERROR: \(error.localizedDescription)"
            log(msg)
            
            if error.localizedDescription.contains("insufficient funds") {
                self.statusMessage = "❌ Rejected: Insufficient POL (Gas)."
            } else if error.localizedDescription.contains("reverted") {
                self.statusMessage = "❌ Rejected: Check Treasury AUT Balance."
            } else {
                self.statusMessage = msg
            }
            self.isLoading = false
        }
    }
    
    // --- HELPERS ---
    private func getWeb3() async throws -> Web3 {
        guard let url = URL(string: rpcURL) else { throw Web3Error.inputError(desc: "URL Error") }
        let provider = try await Web3HttpProvider(url: url, network: .Custom(networkID: chainID))
        let web3 = Web3(provider: provider)
        guard let keyData = Data.fromHex(privateKey) else { throw Web3Error.inputError(desc: "Key Error") }
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
