import SwiftUI

// MARK: - LeaderboardView — the Toy Mint scoreboard panel.
//
// The physical tally board on the machine: cream rows on petrol, monospaced
// ranks and scores, gold / chrome / copper on the podium. Firebase fetch and
// pull-to-refresh behaviour are unchanged from the previous version.

struct LeaderboardView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Copper is not in the shared token set — the design brief lists it only
    // for third place, so it lives inline here instead of the asset catalog.
    private static let mintCopper = Color(red: 0.72, green: 0.45, blue: 0.20)

    var body: some View {
        ZStack {
            Color.mintPetrol.ignoresSafeArea()

            content
        }
        .preferredColorScheme(.dark)
        .navigationTitle(Text("leaderboard_title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.mintPetrol, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await firebaseManager.fetchLeaderboard()
        }
    }

    // MARK: - Content states

    @ViewBuilder
    private var content: some View {
        if firebaseManager.isFetching && firebaseManager.leaderboard.isEmpty {
            loadingState
        } else if firebaseManager.leaderboard.isEmpty {
            emptyState
        } else {
            scoreboard
        }
    }

    private var loadingState: some View {
        VStack(spacing: ToyMint.Spacing.m) {
            ProgressView()
                .tint(.mintCream)
            Text("leaderboard_loading")
                .font(ToyMintFont.caption)
                .foregroundColor(.mintCream.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var emptyState: some View {
        VStack(spacing: ToyMint.Spacing.m) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .semibold))
                .foregroundColor(.mintYellow)
                .accessibilityHidden(true)
            Text("leaderboard_empty")
                .font(ToyMintFont.body)
                .foregroundColor(.mintCream)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, ToyMint.Spacing.xl)
    }

    private var scoreboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ToyMint.Spacing.l) {
                topRule
                rows
            }
            .padding(.horizontal, ToyMint.Spacing.l)
            .padding(.top, ToyMint.Spacing.m)
            .padding(.bottom, ToyMint.Spacing.xl)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .refreshable {
            await firebaseManager.fetchLeaderboard()
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Sections

    private var topRule: some View {
        HStack(alignment: .top, spacing: ToyMint.Spacing.s) {
            Image(systemName: "hourglass.circle")
                .foregroundColor(.mintYellow)
                .font(.system(size: 20, weight: .semibold))
                .accessibilityHidden(true)
            Text("mint_leaderboard_rule")
                .font(ToyMintFont.caption)
                .foregroundColor(.mintCream)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, ToyMint.Spacing.m)
        .padding(.horizontal, ToyMint.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .fill(Color.mintPetrolSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .strokeBorder(Color.mintYellow.opacity(0.35), lineWidth: ToyMint.Stroke.hair)
        )
        .accessibilityElement(children: .combine)
    }

    private var rows: some View {
        VStack(spacing: ToyMint.Spacing.s) {
            ForEach(Array(firebaseManager.leaderboard.enumerated()), id: \.element.id) { index, entry in
                scoreboardRow(rank: index + 1, entry: entry)
            }
        }
    }

    // MARK: - Row

    private func scoreboardRow(rank: Int, entry: LeaderboardEntry) -> some View {
        let onPodium = rank <= 3
        let accent = rankColor(for: rank)

        return HStack(spacing: ToyMint.Spacing.m) {
            rankBadge(rank: rank, accent: accent)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName)
                    .font(ToyMintFont.section)
                    .foregroundColor(onPodium ? .mintPetrolDeep : .mintCream)
                    .lineLimit(1)
                Text(gameTypeLabel(for: entry.gameType))
                    .font(ToyMintFont.caption)
                    .foregroundColor(onPodium
                                     ? .mintPetrolDeep.opacity(0.7)
                                     : .mintCream.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer(minLength: ToyMint.Spacing.s)

            Text("\(entry.score)")
                .font(ToyMintFont.counter)
                .monospacedDigit()
                .foregroundColor(onPodium ? .mintPetrolDeep : accent)
        }
        .padding(.vertical, ToyMint.Spacing.m)
        .padding(.horizontal, ToyMint.Spacing.l)
        .frame(minHeight: 64)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .fill(onPodium ? Color.mintCream : Color.mintPetrolSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .strokeBorder(onPodium ? accent.opacity(0.9) : Color.mintChrome.opacity(0.35),
                              lineWidth: onPodium ? ToyMint.Stroke.panel : ToyMint.Stroke.hair)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(
            format: NSLocalizedString("mint_leaderboard_row_accessibility",
                                      comment: "Rank %d, %@, %@, score %d"),
            rank, entry.playerName, gameTypeLabel(for: entry.gameType), entry.score
        )))
    }

    // MARK: - Rank badge

    @ViewBuilder
    private func rankBadge(rank: Int, accent: Color) -> some View {
        HStack(spacing: ToyMint.Spacing.xs) {
            if rank <= 3 {
                Image(systemName: rank == 1 ? "crown.fill" : "medal.fill")
                    .foregroundColor(accent)
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(rankLabel(for: rank))
                .font(.system(.headline, design: .monospaced).weight(.semibold))
                .foregroundColor(rank <= 3 ? accent : .mintCream.opacity(0.8))
                .monospacedDigit()
        }
        .frame(minWidth: 60, alignment: .leading)
    }

    // MARK: - Helpers

    private func rankLabel(for rank: Int) -> String {
        rank <= 3 ? "#\(rank)" : "\(rank)."
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return .mintYellow
        case 2: return .mintChrome
        case 3: return Self.mintCopper
        default: return .mintCream
        }
    }

    private func gameTypeLabel(for gameType: String) -> String {
        switch gameType {
        case "shapes":  return NSLocalizedString("game_type_shapes",  comment: "")
        case "letters": return NSLocalizedString("game_type_letters", comment: "")
        case "numbers": return NSLocalizedString("game_type_numbers", comment: "")
        default:        return gameType.capitalized
        }
    }
}

// MARK: - Preview

#Preview {
    // Seed a mock leaderboard so the preview renders both podium and body rows.
    let seed: [LeaderboardEntry] = [
        .init(id: "1", playerName: "Roel",   score: 42, gameType: "shapes",
              deviceID: "d1", timestamp: .init(), gameTime: 20, numberOfItems: 6),
        .init(id: "2", playerName: "Alex",   score: 38, gameType: "letters",
              deviceID: "d2", timestamp: .init(), gameTime: 15, numberOfItems: 8),
        .init(id: "3", playerName: "Mira",   score: 33, gameType: "numbers",
              deviceID: "d3", timestamp: .init(), gameTime: 10, numberOfItems: 5),
        .init(id: "4", playerName: "Jasper", score: 27, gameType: "shapes",
              deviceID: "d4", timestamp: .init(), gameTime: 12, numberOfItems: 4),
        .init(id: "5", playerName: "Nadia",  score: 19, gameType: "letters",
              deviceID: "d5", timestamp: .init(), gameTime: 10, numberOfItems: 6),
    ]
    FirebaseManager.shared.leaderboard = seed

    return NavigationStack {
        LeaderboardView()
    }
    .preferredColorScheme(.dark)
}
