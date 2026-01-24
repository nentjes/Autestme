import Foundation
import BigInt
import web3swift
import Web3Core
import SwiftUI

@MainActor
class Web3Manager: ObservableObject {
    static let shared = Web3Manager()
    
    // --- 1. CONFIGURATION ---
    // 🔹 FROM TESTNET ➜ PRODUCTION
    private let rpcURL = "https://polygon-rpc.com"              // <- mainnet instead of Amoy
    private let chainID = BigUInt(137)                          // <- 137 = Polygon mainnet

    // Sensitive data from Secrets.swift
    private let contractAddressString = Secrets.contractAddress
    private let privateKey = Secrets.privateKeyGameTreasury   // Key for "Game Treasury" wallet
    
    // --- 2. STATUS ---
    @Published var statusMessage: String = "Ready to connect"
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false
    
    // This address is set from StartScreen (player wallet)
    @Published var recipientAddress: String = ""

    // Own default wallet (Game Treasury)
    @Published var defaultRecipientAddress: String = ""

    // Log for debug sheet
    @Published var debugLog: String = ""
    
    // --- 3. Simple ERC-20 ABI ---
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
    
    // Logging helper
    private func log(_ message: String) {
        print(message)
        debugLog += message + "\n"
    }
    
    // --- 4. CONNECT & DIAGNOSTICS ---
    
    func connect() async {
        isLoading = true
        statusMessage = "Running diagnostics..."
        debugLog = "--- START DIAGNOSTICS ---\n"

        // Check Secrets
        if privateKey.isEmpty || privateKey.contains("PASTE") {
            let msg = "❌ Please configure Secrets.swift first (privateKeyGameTreasury)."
            statusMessage = msg
            log(msg)
            isLoading = false
            return
        }

        // Run connection with timeout to prevent UI freeze
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    await self.runDiagnostics()
                    _ = try await self.getWeb3()
                }

                group.addTask {
                    try await Task.sleep(for: .seconds(10)) // 10 second timeout
                    throw CancellationError()
                }

                // Wait for first to complete, cancel the other
                try await group.next()
                group.cancelAll()
            }
            isConnected = true
            statusMessage = "✅ Connected as Game Treasury"
        } catch is CancellationError {
            let msg = "⏱️ Connection timeout - check your internet"
            statusMessage = msg
            log(msg)
        } catch {
            let msg = "❌ Connection error: \(error.localizedDescription)"
            statusMessage = msg
            log(msg)
        }

        isLoading = false
    }
    
    func runDiagnostics() async {
        log("\n🕵️‍♂️ --- START DIAGNOSTICS ---")
        
        guard let myAddress = walletAddress(from: privateKey) else {
            log("❌ ERROR: Invalid private key.")
            return
        }
        
        // Default address = treasury address
        defaultRecipientAddress = myAddress.address
        log("🏠 DEFAULT RECIPIENT (App Treasury): \(defaultRecipientAddress)")
        log("🆔 SENDER (Game Treasury): \(myAddress.address)")
        
        do {
            let web3 = try await getWeb3()
            
            // 1. Check POL (gas)
            let polBalance = try await web3.eth.getBalance(for: myAddress)
            let polDouble = Double(polBalance.description) ?? 0.0
            let polString = String(format: "%.4f", polDouble / 1e18)
            log("⛽️ GAS BALANCE: \(polString) POL")
            
            if polBalance == 0 {
                log("⚠️ Game Treasury has 0 POL (no gas).")
            }
            
            // 2. Check token balance Treasury
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
                            log("💰 AUTESTME BALANCE (Treasury): \(autString) AUT")
                            
                            if bal == 0 {
                                log("⚠️ Treasury has 0 AUT.")
                            }
                        } else {
                            log("⚠️ balanceOf returned a response, but no BigUInt.")
                        }
                    } catch {
                        log("❌ 'balanceOf' failed: \(error.localizedDescription)")
                    }
                } else {
                    log("❌ Cannot create readOperation('balanceOf').")
                }
            } else {
                log("❌ Invalid contract address or ABI error.")
            }
            
        } catch {
            log("❌ DIAGNOSTICS ERROR: \(error)")
        }
        
        log("🕵️‍♂️ --- END DIAGNOSTICS ---\n")
    }
    
    // --- 5. REWARD FUNCTION ---
    
    func rewardPlayer(amount: Int) async {
        if privateKey.isEmpty { return }
        
        isLoading = true
        statusMessage = "Sending reward (\(amount) AUT)..."
        
        guard !recipientAddress.isEmpty else {
            statusMessage = "❌ No player address known. (This should not happen.)"
            isLoading = false
            return
        }
        
        guard recipientAddress.hasPrefix("0x"),
              recipientAddress.count == 42 else {
            statusMessage = "❌ Invalid player address format."
            isLoading = false
            return
        }
        
        do {
            let web3 = try await getWeb3()
            
            guard let contractAddress = EthereumAddress(contractAddressString) else {
                throw Web3Error.inputError(desc: "Contract address error")
            }
            guard let contract = web3.contract(minimalABI, at: contractAddress, abiVersion: 2) else {
                throw Web3Error.inputError(desc: "Contract not found")
            }
            
            guard let treasuryAddress = walletAddress(from: privateKey) else {
                throw Web3Error.inputError(desc: "Treasury key error")
            }
            
            guard let playerAddress = EthereumAddress(recipientAddress) else {
                throw Web3Error.inputError(desc: "Invalid player address")
            }
            
            let amountBigInt = BigUInt(amount) * BigUInt(10).power(18)
            let parameters: [Any] = [playerAddress, amountBigInt]
            
            log("💸 Sending \(amount) AUT")
            log("FROM: \(treasuryAddress.address)")
            log("TO: \(playerAddress.address)")
            
            guard let writeOperation = contract.createWriteOperation("transfer", parameters: parameters) else {
                throw Web3Error.inputError(desc: "Function 'transfer' not found")
            }
            
            writeOperation.transaction.from = treasuryAddress
            writeOperation.transaction.chainID = chainID
            
            let gasPrice = BigUInt(60_000_000_000) // 60 Gwei
            let policies = Policies(
                gasLimitPolicy: .automatic,
                gasPricePolicy: .manual(gasPrice)
            )
            
            let tx = try await writeOperation.writeToChain(password: "", policies: policies)
            
            statusMessage = "✅ \(amount) AUT sent! Hash: \(tx.hash.prefix(6))..."
            log("✅ SUCCESS: \(tx.hash)")
            isLoading = false
            
        } catch {
            let msg = "❌ TRANSACTION ERROR: \(error.localizedDescription)"
            log(msg)
            
            if error.localizedDescription.contains("insufficient funds") {
                statusMessage = "❌ Insufficient POL (gas) in Treasury."
            } else if error.localizedDescription.contains("reverted") {
                statusMessage = "❌ Transaction reverted (check AUT balance)."
            } else {
                statusMessage = msg
            }
            isLoading = false
        }
    }
    
    // --- 6. HELPER FUNCTIONS ---
    
    private func getWeb3() async throws -> Web3 {
        guard let url = URL(string: rpcURL) else {
            throw Web3Error.inputError(desc: "RPC URL error")
        }
        let provider = try await Web3HttpProvider(url: url, network: .Custom(networkID: chainID))
        let web3 = Web3(provider: provider)
        
        guard let keyData = Data.fromHex(privateKey) else {
            throw Web3Error.inputError(desc: "Private key hex error")
        }
        
        guard let keystore = try EthereumKeystoreV3(privateKey: keyData, password: "") else {
            throw Web3Error.inputError(desc: "Failed to create keystore")
        }
        web3.addKeystoreManager(KeystoreManager([keystore]))
        return web3
    }
    
    private func walletAddress(from privateKeyHex: String) -> EthereumAddress? {
        guard let data = Data.fromHex(privateKeyHex) else { return nil }
        let keystore = try? EthereumKeystoreV3(privateKey: data, password: "")
        return keystore?.addresses?.first
    }
}
