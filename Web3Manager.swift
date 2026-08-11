import Foundation
import BigInt
import web3swift
import Web3Core
import FirebaseFunctions
import SwiftUI

/// Talks to the `claimReward` Cloud Function to sign and broadcast AUT
/// reward payouts. Injected into Web3Manager so tests can substitute a
/// fake claimer instead of hitting the network / Firebase Functions.
protocol RewardClaiming {
    func claim(recipient: String, amount: Int, gameId: UUID, deviceId: String) async throws -> RewardClaimResponse
}

struct RewardClaimResponse {
    let status: String
    let txHash: String?
}

final class FirebaseFunctionsRewardClaimer: RewardClaiming {
    private let functions = Functions.functions()

    func claim(recipient: String, amount: Int, gameId: UUID, deviceId: String) async throws -> RewardClaimResponse {
        let result = try await functions.httpsCallable("claimReward").call([
            "recipientAddress": recipient,
            "amount": amount,
            "gameId": gameId.uuidString,
            "deviceId": deviceId,
        ])
        let data = result.data as? [String: Any]
        return RewardClaimResponse(
            status: data?["status"] as? String ?? "unknown",
            txHash: data?["txHash"] as? String
        )
    }
}

@MainActor
class Web3Manager: ObservableObject {
    static let shared = Web3Manager()

    // --- 1. CONFIGURATION ---
    private let rpcURL = "https://polygon-bor-rpc.publicnode.com"

    // Contract address (public info)
    private let contractAddressString = Secrets.contractAddress

    /// The game treasury's public address. Safe to hardcode — it is not a
    /// secret. Its PRIVATE key never lives in this app: every payout is
    /// signed server-side by the `claimReward` Cloud Function, which is the
    /// only place that key is ever loaded (from Secret Manager).
    let defaultRecipientAddress: String = Secrets.GameTreasuryWalletAddress

    // --- 2. STATUS ---
    @Published var statusMessage: String = "Ready to connect"
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false

    // Set from StartScreen (player wallet, or the treasury's own address as fallback)
    @Published var recipientAddress: String = ""

    // Log for debug sheet
    @Published var debugLog: String = ""

    // --- 3. Read-only ERC-20 ABI — balance checks only, no signing capability lives here ---
    private let balanceOfABI = """
    [
        {
            "constant": true,
            "inputs": [{"name": "_owner", "type": "address"}],
            "name": "balanceOf",
            "outputs": [{"name": "balance", "type": "uint256"}],
            "type": "function"
        }
    ]
    """

    private let claimer: RewardClaiming
    private static let pendingClaimDefaultsKey = "com.autestme.pendingRewardClaim"

    init(claimer: RewardClaiming = FirebaseFunctionsRewardClaimer()) {
        self.claimer = claimer
    }

    private func log(_ message: String) {
        print(message)
        debugLog += message + "\n"
    }

    // --- 4. CONNECT & DIAGNOSTICS (read-only, no private key involved) ---

    func connect() async {
        isLoading = true
        statusMessage = "Running diagnostics..."
        debugLog = "--- START DIAGNOSTICS ---\n"

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask { await self.runDiagnostics() }
                group.addTask {
                    try await Task.sleep(for: .seconds(10)) // 10 second timeout
                    throw CancellationError()
                }
                try await group.next()
                group.cancelAll()
            }
            isConnected = true
            statusMessage = "✅ Connected"
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
        log("🏠 GAME TREASURY (public address): \(defaultRecipientAddress)")

        guard let treasuryAddress = EthereumAddress(defaultRecipientAddress) else {
            log("❌ ERROR: Configured treasury address is invalid.")
            return
        }

        do {
            let web3 = try await getWeb3()

            let polBalance = try await web3.eth.getBalance(for: treasuryAddress)
            let polDouble = Double(polBalance.description) ?? 0.0
            log("⛽️ GAS BALANCE: \(String(format: "%.4f", polDouble / 1e18)) POL")
            if polBalance == 0 {
                log("⚠️ Game Treasury has 0 POL (no gas).")
            }

            if let contractAddress = EthereumAddress(contractAddressString),
               let contract = web3.contract(balanceOfABI, at: contractAddress, abiVersion: 2) {
                log("📜 CONTRACT: \(contractAddress.address)")

                if let readOp = contract.createReadOperation("balanceOf", parameters: [treasuryAddress]) {
                    readOp.transaction.from = treasuryAddress
                    do {
                        let response = try await readOp.callContractMethod()
                        let balance = (response["balance"] as? BigUInt) ?? (response["0"] as? BigUInt)
                        if let bal = balance {
                            let autDouble = Double(bal.description) ?? 0.0
                            log("💰 AUTESTME BALANCE (Treasury): \(String(format: "%.2f", autDouble / 1e18)) AUT")
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

    // --- 5. REWARD CLAIMS (signed server-side by the claimReward Cloud Function) ---

    /// Requests a reward payout for a completed game. `gameId` doubles as
    /// the server's idempotency key — safe to call more than once for the
    /// same game (e.g. after a retry), it will never pay out twice.
    func rewardPlayer(amount: Int, gameId: UUID, deviceId: String) async {
        guard amount > 0 else { return }
        guard recipientAddress.hasPrefix("0x"), recipientAddress.count == 42 else {
            statusMessage = "❌ Invalid player address format."
            return
        }

        isLoading = true
        statusMessage = "Sending reward (\(amount) AUT)..."
        persistPendingClaim(amount: amount, gameId: gameId, recipient: recipientAddress)

        await submitClaim(amount: amount, gameId: gameId, recipient: recipientAddress, deviceId: deviceId)

        isLoading = false
    }

    /// Retries a reward claim left over from a previous app launch that
    /// never confirmed (e.g. the app was killed mid-request). Safe to call
    /// unconditionally on launch — if the claim already succeeded, the
    /// server's idempotency check makes this a no-op.
    func retryPendingClaimIfAny(deviceId: String) async {
        guard let pending = loadPendingClaim() else { return }
        log("🔁 Retrying a reward claim from a previous session (game \(pending.gameId)).")
        await submitClaim(amount: pending.amount, gameId: pending.gameId, recipient: pending.recipient, deviceId: deviceId)
    }

    private func submitClaim(amount: Int, gameId: UUID, recipient: String, deviceId: String) async {
        do {
            let response = try await claimer.claim(recipient: recipient, amount: amount, gameId: gameId, deviceId: deviceId)
            let hashSuffix = response.txHash.map { " Hash: \(String($0.prefix(10)))..." } ?? ""
            statusMessage = "✅ \(amount) AUT sent!\(hashSuffix)"
            log("✅ SUCCESS: \(response.txHash ?? response.status)")
            clearPendingClaim()
        } catch let error as NSError {
            handleClaimError(error)
        }
    }

    private func handleClaimError(_ error: NSError) {
        log("❌ CLAIM ERROR: \(error.localizedDescription)")

        switch FunctionsErrorCode(rawValue: error.code) {
        case .resourceExhausted:
            statusMessage = "❌ Daily reward limit reached. Try again tomorrow."
            clearPendingClaim() // not retryable — resubmitting would just hit the same cap
        case .invalidArgument:
            statusMessage = "❌ \(error.localizedDescription)"
            clearPendingClaim() // the request itself was rejected — retrying won't help
        case .unauthenticated, .permissionDenied:
            statusMessage = "❌ Could not verify this app instance. Please update the app."
            clearPendingClaim()
        default:
            // Likely a transient network/server issue — keep the pending
            // claim on disk so retryPendingClaimIfAny() can try again.
            statusMessage = "❌ Could not reach the reward server. Will retry automatically."
        }
    }

    private struct PendingClaim: Codable {
        let amount: Int
        let gameId: UUID
        let recipient: String
    }

    private func persistPendingClaim(amount: Int, gameId: UUID, recipient: String) {
        let claim = PendingClaim(amount: amount, gameId: gameId, recipient: recipient)
        guard let data = try? JSONEncoder().encode(claim) else { return }
        UserDefaults.standard.set(data, forKey: Self.pendingClaimDefaultsKey)
    }

    private func loadPendingClaim() -> PendingClaim? {
        guard let data = UserDefaults.standard.data(forKey: Self.pendingClaimDefaultsKey) else { return nil }
        return try? JSONDecoder().decode(PendingClaim.self, from: data)
    }

    private func clearPendingClaim() {
        UserDefaults.standard.removeObject(forKey: Self.pendingClaimDefaultsKey)
    }

    // --- 6. HELPERS ---

    private func getWeb3() async throws -> Web3 {
        guard let url = URL(string: rpcURL) else {
            throw Web3Error.inputError(desc: "RPC URL error")
        }
        let provider = try await Web3HttpProvider(url: url, network: .Custom(networkID: BigUInt(137)))
        return Web3(provider: provider)
    }
}
