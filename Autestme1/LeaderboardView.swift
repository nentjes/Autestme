import SwiftUI

struct LeaderboardView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared

    var body: some View {
        Group {
            if firebaseManager.isFetching {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("leaderboard_loading")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if firebaseManager.leaderboard.isEmpty {
                Text("leaderboard_empty")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(Array(firebaseManager.leaderboard.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Text(rankLabel(for: index + 1))
                            .font(.headline)
                            .foregroundColor(rankColor(for: index + 1))
                            .frame(width: 36, alignment: .center)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.playerName)
                                .font(.headline)
                            Text(entry.gameType.capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(entry.score)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(rankColor(for: index + 1))
                    }
                }
                .refreshable {
                    await firebaseManager.fetchLeaderboard()
                }
            }
        }
        .navigationTitle(Text("leaderboard_title"))
        .task {
            await firebaseManager.fetchLeaderboard()
        }
    }

    private func rankLabel(for rank: Int) -> String {
        switch rank {
        case 1: return "#1"
        case 2: return "#2"
        case 3: return "#3"
        default: return "\(rank)."
        }
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.75, blue: 0.0)   // gold
        case 2: return Color(red: 0.65, green: 0.65, blue: 0.65) // silver
        case 3: return Color(red: 0.72, green: 0.45, blue: 0.20) // bronze
        default: return .primary
        }
    }
}

#Preview {
    NavigationStack {
        LeaderboardView()
    }
}
