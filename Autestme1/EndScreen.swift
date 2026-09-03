import SwiftUI

// MARK: - EndScreen — the Toy Mint counting console.
//
// The player enters how many times they saw each item, then reveals the
// score. Firebase submits, Web3 pays out — all of that logic is preserved
// verbatim from before. This file is a visual pass only.

struct EndScreen: View {
    @Binding var shapeCounts: [ShapeType: Int]
    let dismissAction: () -> Void
    let restartAction: () -> Void
    @ObservedObject var gameLogic: GameLogic
    @Binding var navigationPath: NavigationPath

    // WEB3
    @StateObject private var web3Manager = Web3Manager.shared

    // FIREBASE
    @StateObject private var firebaseManager = FirebaseManager.shared

    @State private var enteredShapes: [ShapeType: Int] = [:]
    @State private var enteredLetters: [Character: Int] = [:]
    @State private var enteredNumbers: [Int: Int] = [:]
    @State private var isShowingResults = false
    @State private var textInputs: [AnyHashable: String] = [:]
    @FocusState private var focusedField: AnyHashable?

    // Presentation-only state (not persisted, not networked).
    @State private var isNewHighscore: Bool = false
    @State private var showStatusLade: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Derived

    /// Total number of correct answers (existing scoring, unchanged).
    private var totalCorrect: Int {
        switch gameLogic.gameVersion {
        case .shapes:
            return shapeCounts.reduce(0) { acc, pair in
                let entered = enteredShapes[pair.key] ?? 0
                return acc + (entered == pair.value ? 1 : 0)
            }
        case .letters:
            return gameLogic.letterCounts
                .filter { $0.value > 0 }
                .reduce(0) { acc, pair in
                    let entered = enteredLetters[pair.key] ?? 0
                    return acc + (entered == pair.value ? 1 : 0)
                }
        case .numbers:
            return gameLogic.numberCounts
                .filter { $0.value > 0 }
                .reduce(0) { acc, pair in
                    let entered = enteredNumbers[pair.key] ?? 0
                    return acc + (entered == pair.value ? 1 : 0)
                }
        }
    }

    /// Maximum possible score for the played round.
    private var maxScore: Int {
        switch gameLogic.gameVersion {
        case .shapes:  return shapeCounts.count
        case .letters: return gameLogic.letterCounts.filter { $0.value > 0 }.count
        case .numbers: return gameLogic.numberCounts.filter { $0.value > 0 }.count
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.mintPetrol.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: ToyMint.Spacing.xl) {
                    if isShowingResults {
                        resultsSection
                    } else {
                        entrySection
                    }
                }
                .padding(.horizontal, ToyMint.Spacing.l)
                .padding(.vertical, ToyMint.Spacing.l)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.mintPetrol, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            guard !isShowingResults else { return }
            let firstItem: AnyHashable? = {
                switch gameLogic.gameVersion {
                case .shapes:
                    return shapeCounts.keys
                        .sorted { $0.rawValue < $1.rawValue }
                        .first
                case .letters:
                    return gameLogic.letterCounts
                        .filter { $0.value > 0 }
                        .map { $0.key }
                        .sorted()
                        .first
                case .numbers:
                    return gameLogic.numberCounts
                        .filter { $0.value > 0 }
                        .map { $0.key }
                        .sorted()
                        .first
                }
            }()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedField = firstItem
            }
        }
    }

    // MARK: - Entry section

    private var entrySection: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.l) {
            VStack(alignment: .leading, spacing: ToyMint.Spacing.xs) {
                Text("mint_end_entry_title")
                    .font(ToyMintFont.display)
                    .foregroundColor(.mintCreamBright)
                    .accessibilityAddTraits(.isHeader)
                Text("mint_end_entry_prompt")
                    .font(ToyMintFont.body)
                    .foregroundColor(.mintCream.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            entryRows

            Button {
                submitAnswers()
            } label: {
                HStack(spacing: ToyMint.Spacing.s) {
                    Image(systemName: "checkmark.seal.fill")
                        .accessibilityHidden(true)
                    Text("end_screen_show_results_button")
                }
            }
            .buttonStyle(MintPrimaryButtonStyle())
            .accessibilityHint(Text("mint_end_show_results_hint"))
        }
    }

    @ViewBuilder
    private var entryRows: some View {
        switch gameLogic.gameVersion {
        case .shapes:
            let items = shapeCounts.keys.sorted { $0.rawValue < $1.rawValue }
            VStack(spacing: ToyMint.Spacing.s) {
                ForEach(items, id: \.self) { item in
                    entryRow(
                        key: AnyHashable(item),
                        label: item.displayName,
                        binding: shapesEntryBinding(item)
                    )
                }
            }
        case .letters:
            let items = gameLogic.letterCounts
                .filter { $0.value > 0 }
                .map { $0.key }
                .sorted()
            VStack(spacing: ToyMint.Spacing.s) {
                ForEach(items, id: \.self) { item in
                    entryRow(
                        key: AnyHashable(item),
                        label: String(item),
                        binding: lettersEntryBinding(item)
                    )
                }
            }
        case .numbers:
            let items = gameLogic.numberCounts
                .filter { $0.value > 0 }
                .map { $0.key }
                .sorted()
            VStack(spacing: ToyMint.Spacing.s) {
                ForEach(items, id: \.self) { item in
                    entryRow(
                        key: AnyHashable(item),
                        label: String(item),
                        binding: numbersEntryBinding(item)
                    )
                }
            }
        }
    }

    private func entryRow(key: AnyHashable, label: String, binding: Binding<String>) -> some View {
        HStack(spacing: ToyMint.Spacing.m) {
            Text(label)
                .font(ToyMintFont.section)
                .foregroundColor(.mintPetrolDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            TextField("0", text: binding)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(ToyMintFont.counter)
                .foregroundColor(.mintPetrolDeep)
                .frame(width: 84, height: ToyMint.Layout.controlHeight)
                .background(
                    RoundedRectangle(cornerRadius: ToyMint.Radius.s, style: .continuous)
                        .fill(Color.mintCreamBright)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: ToyMint.Radius.s, style: .continuous)
                        .strokeBorder(Color.mintCoral, lineWidth: ToyMint.Stroke.panel)
                )
                .focused($focusedField, equals: key)
                .accessibilityLabel(Text(String(
                    format: NSLocalizedString("mint_end_entry_accessibility",
                                              comment: "Count for %@"),
                    label
                )))
                .accessibilityHint(Text("mint_end_entry_hint"))
        }
        .padding(.vertical, ToyMint.Spacing.s)
        .padding(.horizontal, ToyMint.Spacing.l)
        .frame(minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .fill(Color.mintCream)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .strokeBorder(Color.mintChrome.opacity(0.55), lineWidth: ToyMint.Stroke.hair)
        )
    }

    // MARK: - Result section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.xl) {
            scoreHeader
            if isNewHighscore { highscoreBadge }
            waitRuleFooter
            resultsPanel
            rewardStatusLade
            replayButton
        }
    }

    private var scoreHeader: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.xs) {
            Text("mint_end_score_title")
                .font(ToyMintFont.section)
                .foregroundColor(.mintCream.opacity(0.75))
            HStack(alignment: .lastTextBaseline, spacing: ToyMint.Spacing.s) {
                Text("\(totalCorrect)")
                    .font(ToyMintFont.counterXL)
                    .foregroundColor(.mintYellow)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(String(format: NSLocalizedString("mint_end_score_of",
                                                     comment: "of %d"), maxScore))
                    .font(ToyMintFont.title)
                    .foregroundColor(.mintCream.opacity(0.7))
            }
        }
        .mintPanel(.petrol)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(
            format: NSLocalizedString("mint_end_score_accessibility",
                                      comment: "Score %d out of %d"),
            totalCorrect, maxScore
        )))
    }

    private var highscoreBadge: some View {
        HStack(spacing: ToyMint.Spacing.s) {
            Image(systemName: "crown.fill")
                .foregroundColor(.mintYellow)
                .font(.system(size: 20, weight: .semibold))
                .accessibilityHidden(true)
            Text("mint_end_highscore_new")
                .font(ToyMintFont.actionLabel)
                .foregroundColor(.mintCreamBright)
            Spacer(minLength: 0)
        }
        .padding(.vertical, ToyMint.Spacing.m)
        .padding(.horizontal, ToyMint.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .fill(Color.mintYellow.opacity(0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .strokeBorder(Color.mintYellow.opacity(0.55), lineWidth: ToyMint.Stroke.hair)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mint_end_highscore_new_accessibility"))
    }

    private var waitRuleFooter: some View {
        HStack(alignment: .top, spacing: ToyMint.Spacing.s) {
            Image(systemName: "hourglass.circle")
                .foregroundColor(.mintCream.opacity(0.7))
                .accessibilityHidden(true)
            Text("mint_end_rule_wait")
                .font(ToyMintFont.caption)
                .foregroundColor(.mintCream.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var resultsPanel: some View {
        switch gameLogic.gameVersion {
        case .shapes:
            let rows = shapeCounts
                .sorted { $0.key.rawValue < $1.key.rawValue }
                .map { (label: $0.key.displayName,
                        entered: enteredShapes[$0.key] ?? 0,
                        actual: $0.value) }
            VStack(spacing: ToyMint.Spacing.s) { ForEach(rows, id: \.label, content: resultRow) }
        case .letters:
            let rows = gameLogic.letterCounts
                .filter { $0.value > 0 }
                .sorted { $0.key < $1.key }
                .map { (label: String($0.key),
                        entered: enteredLetters[$0.key] ?? 0,
                        actual: $0.value) }
            VStack(spacing: ToyMint.Spacing.s) { ForEach(rows, id: \.label, content: resultRow) }
        case .numbers:
            let rows = gameLogic.numberCounts
                .filter { $0.value > 0 }
                .sorted { $0.key < $1.key }
                .map { (label: String($0.key),
                        entered: enteredNumbers[$0.key] ?? 0,
                        actual: $0.value) }
            VStack(spacing: ToyMint.Spacing.s) { ForEach(rows, id: \.label, content: resultRow) }
        }
    }

    private func resultRow(label: String, entered: Int, actual: Int) -> some View {
        let skipped = entered == 0 && actual == 0
        let correct = entered == actual
        let ok = correct || skipped
        let statusText = NSLocalizedString(ok ? "mint_end_correct" : "mint_end_incorrect",
                                           comment: "Correct or different marker")
        return HStack(spacing: ToyMint.Spacing.m) {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundColor(ok ? .mintGreen : .mintCoral)
                .font(.system(size: 20, weight: .semibold))
                .accessibilityHidden(true)
            Text(label)
                .font(ToyMintFont.section)
                .foregroundColor(.mintCream)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            Text("\(entered) / \(actual)")
                .font(ToyMintFont.counter)
                .monospacedDigit()
                .foregroundColor(ok ? .mintCream : .mintCoral)
            Text(statusText)
                .font(ToyMintFont.caption.weight(.semibold))
                .foregroundColor(ok ? .mintGreen : .mintCoral)
        }
        .padding(.vertical, ToyMint.Spacing.s)
        .padding(.horizontal, ToyMint.Spacing.m)
        .frame(minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .fill(Color.mintPetrolSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.m, style: .continuous)
                .strokeBorder(Color.mintChrome.opacity(0.35), lineWidth: ToyMint.Stroke.hair)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(
            format: NSLocalizedString("mint_end_result_accessibility",
                                      comment: "%@: %@, you %d actual %d"),
            label, statusText, entered, actual
        )))
    }

    // MARK: - Status lade

    private var rewardStatusLade: some View {
        MintDisclosureLade(
            title: "mint_end_status_title",
            subtitle: "mint_end_status_subtitle",
            isExpanded: $showStatusLade
        ) {
            VStack(alignment: .leading, spacing: ToyMint.Spacing.m) {
                MintStatusLamp(
                    state: rewardLampState,
                    title: rewardLampText,
                    systemImage: "bitcoinsign.circle.fill"
                )

                MintStatusLamp(
                    state: leaderboardLampState,
                    title: leaderboardLampText,
                    systemImage: "list.number"
                )
            }
            .padding(.top, ToyMint.Spacing.s)
        }
    }

    private var rewardLampState: MintStatusLamp.State {
        if web3Manager.isLoading { return .waiting }
        if web3Manager.recipientAddress.isEmpty { return .off }
        return web3Manager.statusMessage.isEmpty ? .waiting : .ok
    }

    private var rewardLampText: String {
        web3Manager.statusMessage.isEmpty
            ? NSLocalizedString("mint_end_reward_idle",
                                comment: "Reward status while waiting")
            : web3Manager.statusMessage
    }

    private var leaderboardLampState: MintStatusLamp.State {
        if firebaseManager.isSubmitting { return .waiting }
        return firebaseManager.statusMessage.isEmpty ? .off : .ok
    }

    private var leaderboardLampText: String {
        firebaseManager.statusMessage.isEmpty
            ? NSLocalizedString("mint_end_leaderboard_idle",
                                comment: "Leaderboard status while waiting")
            : firebaseManager.statusMessage
    }

    // MARK: - Replay

    private var replayButton: some View {
        Button {
            SoundManager.shared.playClick()
            gameLogic.reset()
            navigationPath.removeLast(navigationPath.count)
        } label: {
            HStack(spacing: ToyMint.Spacing.s) {
                Image(systemName: "arrow.uturn.left.circle.fill")
                    .accessibilityHidden(true)
                Text("end_screen_back_button")
            }
        }
        .buttonStyle(MintPrimaryButtonStyle())
        .accessibilityHint(Text("mint_end_replay_hint"))
    }

    // MARK: - Submit

    private func submitAnswers() {
        SoundManager.shared.playClick()

        let previousBest = GameLogic.getHighScore(
            for: gameLogic.player,
            gameVersion: gameLogic.gameVersion
        )
        if totalCorrect > previousBest {
            GameLogic.setHighScore(
                totalCorrect,
                for: gameLogic.player,
                gameVersion: gameLogic.gameVersion
            )
            isNewHighscore = true
        }

        if reduceMotion {
            isShowingResults = true
        } else {
            withAnimation(.easeOut(duration: 0.18)) {
                isShowingResults = true
            }
        }

        // FIREBASE: submit score to global leaderboard.
        Task {
            await firebaseManager.submitScore(
                playerName: gameLogic.player,
                score: totalCorrect,
                gameType: gameLogic.gameVersion,
                gameTime: gameLogic.gameTime,
                numberOfItems: gameLogic.numberOfItems
            )
        }

        // WEB3: actual reward.
        if totalCorrect > 0 && !web3Manager.recipientAddress.isEmpty {
            let rewardAmount = totalCorrect
            Task { await web3Manager.rewardPlayer(amount: rewardAmount) }
        } else if web3Manager.recipientAddress.isEmpty {
            web3Manager.statusMessage = NSLocalizedString(
                "end_screen_rewards_disabled",
                comment: "Status when token rewards are disabled for this game"
            )
        } else {
            web3Manager.statusMessage = NSLocalizedString(
                "end_screen_no_tokens_earned",
                comment: "Status when no tokens were earned (score 0)"
            )
        }

        SoundManager.shared.playResult(success: totalCorrect > 0)
    }

    // MARK: - Text-field bindings

    private func shapesEntryBinding(_ item: ShapeType) -> Binding<String> {
        Binding(
            get: {
                let v = enteredShapes[item] ?? 0
                return v == 0 ? "" : "\(v)"
            },
            set: { newText in
                let filtered = newText.filter { $0.isNumber }
                textInputs[AnyHashable(item)] = filtered
                enteredShapes[item] = Int(filtered) ?? 0
            }
        )
    }

    private func lettersEntryBinding(_ item: Character) -> Binding<String> {
        Binding(
            get: {
                let v = enteredLetters[item] ?? 0
                return v == 0 ? "" : "\(v)"
            },
            set: { newText in
                let filtered = newText.filter { $0.isNumber }
                textInputs[AnyHashable(item)] = filtered
                enteredLetters[item] = Int(filtered) ?? 0
            }
        )
    }

    private func numbersEntryBinding(_ item: Int) -> Binding<String> {
        Binding(
            get: {
                let v = enteredNumbers[item] ?? 0
                return v == 0 ? "" : "\(v)"
            },
            set: { newText in
                let filtered = newText.filter { $0.isNumber }
                textInputs[AnyHashable(item)] = filtered
                enteredNumbers[item] = Int(filtered) ?? 0
            }
        )
    }
}

// MARK: - Preview

#Preview {
    let mockLogic = GameLogic(
        gameTime: 10,
        gameVersion: .shapes,
        colorMode: .fixed,
        displayRate: 3,
        player: "MockPlayer",
        numberOfShapes: 3
    )

    let mockShapeCounts: [ShapeType: Int] = [
        .dot: 5,
        .line: 2,
        .circle: 0
    ]

    Web3Manager.shared.statusMessage = "Wallet ready for Mainnet."
    Web3Manager.shared.recipientAddress = "0xAutestmeTreasuryAddress"

    @State var path = NavigationPath()

    return NavigationStack {
        EndScreen(
            shapeCounts: .constant(mockShapeCounts),
            dismissAction: {},
            restartAction: {},
            gameLogic: mockLogic,
            navigationPath: $path
        )
    }
    .preferredColorScheme(.dark)
}
