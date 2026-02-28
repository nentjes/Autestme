import Foundation
import FirebaseFirestore

// MARK: - LeaderboardEntry model

struct LeaderboardEntry: Identifiable {
    let id: String
    let playerName: String
    let score: Int
    let gameType: String
    let deviceID: String
    let timestamp: Date
    let gameTime: Int
    let numberOfItems: Int
}

// MARK: - GameVersion Firestore extension

extension GameVersion {
    var firestoreValue: String {
        switch self {
        case .shapes:  return "shapes"
        case .letters: return "letters"
        case .numbers: return "numbers"
        }
    }
}

// MARK: - FirebaseManager

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isSubmitting: Bool = false
    @Published var isFetching: Bool = false
    @Published var statusMessage: String = ""

    private let db = Firestore.firestore()

    // Persistent device identifier (no UIKit dependency)
    private let deviceID: String = {
        if let existing = UserDefaults.standard.string(forKey: "autestme_device_id") {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: "autestme_device_id")
        return newID
    }()

    private init() {}

    /// Submit a game score to Firestore
    func submitScore(
        playerName: String,
        score: Int,
        gameType: GameVersion,
        gameTime: Int,
        numberOfItems: Int
    ) async {
        isSubmitting = true
        statusMessage = NSLocalizedString("leaderboard_submitting", comment: "")

        let data: [String: Any] = [
            "playerName": playerName,
            "score": score,
            "gameType": gameType.firestoreValue,
            "deviceID": deviceID,
            "timestamp": FieldValue.serverTimestamp(),
            "gameTime": gameTime,
            "numberOfItems": numberOfItems
        ]

        // Brief UX delay to show "saving" feedback
        try? await Task.sleep(for: .milliseconds(400))

        // Fire the write without waiting for server confirmation.
        // Firestore offline persistence guarantees delivery even without instant server ACK.
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.db.collection("leaderboard").addDocument(data: data)
            } catch {
                // Silent — user already sees success; Firestore will retry if needed
            }
        }

        statusMessage = NSLocalizedString("leaderboard_submitted", comment: "")
        isSubmitting = false
    }

    /// Fetch top 50 leaderboard entries
    func fetchLeaderboard() async {
        isFetching = true

        do {
            let snapshot = try await db.collection("leaderboard")
                .order(by: "score", descending: true)
                .limit(to: 50)
                .getDocuments()

            leaderboard = snapshot.documents.compactMap { doc in
                let data = doc.data()
                guard
                    let playerName = data["playerName"] as? String,
                    !playerName.trimmingCharacters(in: .whitespaces).isEmpty,
                    let score = data["score"] as? Int,
                    let gameType = data["gameType"] as? String,
                    let deviceID = data["deviceID"] as? String,
                    let gameTime = data["gameTime"] as? Int,
                    let numberOfItems = data["numberOfItems"] as? Int
                else { return nil }

                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

                return LeaderboardEntry(
                    id: doc.documentID,
                    playerName: playerName,
                    score: score,
                    gameType: gameType,
                    deviceID: deviceID,
                    timestamp: timestamp,
                    gameTime: gameTime,
                    numberOfItems: numberOfItems
                )
            }
        } catch {
            // Silently handle - leaderboard stays empty on error
        }

        isFetching = false
    }
}
