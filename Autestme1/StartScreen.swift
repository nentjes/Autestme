import SwiftUI

// MARK: - StartScreen — the Toy Mint control panel.
//
// This file is intentionally visual-only. Game, timer, Firebase, Web3 and
// audio logic live in their own files and are untouched by this redesign.

struct StartScreen: View {
    @Binding var navigationPath: NavigationPath

    // Web3 singleton
    @ObservedObject private var web3Manager = Web3Manager.shared

    @State private var gameDuration: Double = 5
    @State private var numberOfShapes: Double = 2
    @State private var shapeDisplayRate: Double = 3
    @State private var selectedColorMode: ColorMode = .fixed
    @State private var selectedGameVersion: GameVersion = .shapes
    @State private var playerName: String = ""
    @State private var currentHighscore: Int = 0

    // Wallet address of the player (Polygon Mainnet)
    @State private var playerWalletAddress: String = ""

    // Rewards drawer state — the explicit, accessible replacement for the
    // previous invisible edge-swipe. The user toggles it on-screen; nothing
    // critical is hidden behind an undiscoverable gesture.
    @AppStorage("cryptoRewardsEnabled") private var isCryptoEnabled: Bool = false
    @State private var showRewardsLade: Bool = false

    // Dialogs
    @State private var showInfoAlert = false
    @State private var showDebugLog = false

    // Keyboard auto-dismiss
    @FocusState private var isPlayerNameFocused: Bool
    @State private var keyboardTimer: Timer?

    // MARK: - Derived data

    private var labelForType: String {
        let key: String
        switch selectedGameVersion {
        case .shapes:  key = "item_type_shapes"
        case .numbers: key = "item_type_numbers"
        case .letters: key = "item_type_letters"
        }
        return NSLocalizedString(key, comment: "Game type label for item counter")
    }

    private var rangeForType: ClosedRange<Double> {
        switch selectedGameVersion {
        case .shapes:  return 1...Double(ShapeType.allCases.count)
        case .numbers: return 1...10
        case .letters: return 1...26
        }
    }

    private var highscoreDisplayValue: String {
        currentHighscore > 0 ? "\(currentHighscore)" : "—"
    }

    private var walletStatusLampState: MintStatusLamp.State {
        if web3Manager.isLoading { return .waiting }
        if !isCryptoEnabled       { return .off }
        return web3Manager.isConnected ? .ok : .warn
    }

    private var walletStatusText: String {
        if !isCryptoEnabled {
            return NSLocalizedString("crypto_rewards_disabled", comment: "Crypto Rewards Disabled")
        }
        return web3Manager.statusMessage.isEmpty
            ? NSLocalizedString("mint_wallet_status_idle", comment: "Waiting for connection")
            : web3Manager.statusMessage
    }

    // Inline validation for the wallet address field. Off-brand system colours
    // never enter the UI — every state maps to a Toy Mint token and always ships
    // with a text label so it works without colour vision.
    private enum WalletValidationState { case empty, valid, invalidFormat }

    private var walletValidationState: WalletValidationState {
        let trimmed = playerWalletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .empty }
        if trimmed.hasPrefix("0x") && trimmed.count == 42 { return .valid }
        return .invalidFormat
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ToyMintBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: ToyMint.Spacing.xl) {
                    header
                    highscoreRow
                    modeSegments
                    machineSettings
                    playerRow
                    startButton
                    rewardsDrawer
                    footer
                }
                .padding(.horizontal, ToyMint.Spacing.l)
                .padding(.top, ToyMint.Spacing.l)
                .padding(.bottom, ToyMint.Spacing.xxl)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            updateHighscore()
            isPlayerNameFocused = false
            if !web3Manager.isConnected && !web3Manager.isLoading {
                Task { await web3Manager.connect() }
            }
        }
        .onChange(of: isPlayerNameFocused) { focused in
            if focused { resetKeyboardTimer() } else {
                keyboardTimer?.invalidate()
                keyboardTimer = nil
            }
        }
        .onChange(of: playerName) { _ in
            if playerName.count > 30 {
                playerName = String(playerName.prefix(30))
            }
            updateHighscore()
            resetKeyboardTimer()
        }
        .onChange(of: selectedGameVersion) { _ in
            // Clamp item slider to the new mode's range.
            let clamped = min(max(numberOfShapes, rangeForType.lowerBound), rangeForType.upperBound)
            if clamped != numberOfShapes { numberOfShapes = clamped }
            updateHighscore()
        }
        .onChange(of: isCryptoEnabled) { enabled in
            if !enabled { playerWalletAddress = "" }
        }
        .sheet(isPresented: $showDebugLog) { debugLogSheet }
        .alert(Text(NSLocalizedString("info_title", comment: "Alert Title")),
               isPresented: $showInfoAlert) {
            Button(NSLocalizedString("alert_button_ok", comment: "OK button")) { }
        } message: {
            Text(NSLocalizedString("info_body", comment: "Game rules")) +
            Text("\n\n") +
            Text(NSLocalizedString("info_crypto_title", comment: "Crypto Rewards Title"))
                .fontWeight(.bold) +
            Text("\n") +
            Text(NSLocalizedString("info_crypto_explanation", comment: "Crypto info"))
        }
        .navigationDestination(for: GameLogic.self) { logic in
            GameContainerView(gameLogic: logic, navigationPath: $navigationPath)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoAlert = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.mintCream)
                }
                .accessibilityLabel(Text("info_button_accessibility"))
                .accessibilityHint(Text("info_button_hint"))
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        MintWordmark(showTagline: true, alignment: .center)
            .padding(.top, ToyMint.Spacing.s)
    }

    // MARK: - Highscore row

    private var highscoreRow: some View {
        HStack(spacing: ToyMint.Spacing.m) {
            MintCounter(
                title: NSLocalizedString("mint_highscore_counter_title", comment: "Your best score"),
                value: highscoreDisplayValue,
                accent: .mintYellow,
                size: .medium
            )

            NavigationLink(destination: LeaderboardView()) {
                HStack(spacing: ToyMint.Spacing.s) {
                    Image(systemName: "list.number")
                        .accessibilityHidden(true)
                    Text("leaderboard_button")
                }
            }
            .buttonStyle(MintSecondaryButtonStyle())
            .accessibilityLabel(Text("leaderboard_button"))
            .accessibilityHint(Text("mint_leaderboard_hint"))
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Mode segments

    private var modeSegments: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.s) {
            Text("mint_mode_section_title")
                .font(ToyMintFont.section)
                .foregroundColor(.mintCream.opacity(0.85))

            MintSegmentedControl(
                selection: $selectedGameVersion,
                items: [
                    .init(value: .shapes,
                          title: NSLocalizedString("game_type_shapes", comment: "Shapes"),
                          glyph: .circle,
                          accessibilityLabel: NSLocalizedString("game_type_shapes", comment: "Shapes")),
                    .init(value: .letters,
                          title: NSLocalizedString("game_type_letters", comment: "Letters"),
                          glyph: .letter(NSLocalizedString("mint_letter_glyph", comment: "Letter glyph, e.g. A")),
                          accessibilityLabel: NSLocalizedString("game_type_letters", comment: "Letters")),
                    .init(value: .numbers,
                          title: NSLocalizedString("game_type_numbers", comment: "Numbers"),
                          glyph: .digit(NSLocalizedString("mint_digit_glyph", comment: "Digit glyph, e.g. 3")),
                          accessibilityLabel: NSLocalizedString("game_type_numbers", comment: "Numbers"))
                ]
            )
        }
    }

    // MARK: - Machine settings

    private var machineSettings: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.l) {
            Text("mint_settings_section_title")
                .font(ToyMintFont.section)
                .foregroundColor(.mintCream.opacity(0.85))

            VStack(alignment: .leading, spacing: ToyMint.Spacing.l) {
                MintSliderRow(
                    title: NSLocalizedString("mint_duration_title", comment: "Duration"),
                    value: $gameDuration,
                    range: 5...30,
                    valueLabel: String(format: NSLocalizedString("mint_seconds_short", comment: "%ds"),
                                       Int(gameDuration)),
                    accessibilityValueLabel: String(format: NSLocalizedString("mint_seconds_verbose",
                                                                              comment: "%d seconds"),
                                                    Int(gameDuration))
                )

                MintSliderRow(
                    title: NSLocalizedString("mint_speed_title", comment: "Speed"),
                    value: $shapeDisplayRate,
                    range: 1...10,
                    valueLabel: "\(Int(shapeDisplayRate))",
                    accessibilityValueLabel: String(format: NSLocalizedString("mint_items_per_second",
                                                                              comment: "%d items per second"),
                                                    Int(shapeDisplayRate))
                )

                MintSliderRow(
                    title: String(format: NSLocalizedString("mint_item_count_title",
                                                            comment: "Number of %@"),
                                  labelForType),
                    value: $numberOfShapes,
                    range: rangeForType,
                    valueLabel: "\(Int(numberOfShapes))",
                    accessibilityValueLabel: String(format: NSLocalizedString("mint_item_count_value",
                                                                              comment: "%d %@"),
                                                    Int(numberOfShapes), labelForType)
                )

                colorModeRow
            }
        }
        .mintPanel(.petrol)
    }

    private var colorModeRow: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.s) {
            Text("color_mode_label")
                .font(ToyMintFont.section)
                .foregroundColor(.mintCream)
            Picker(selection: $selectedColorMode) {
                Text("color_mode_fixed").tag(ColorMode.fixed)
                Text("color_mode_random").tag(ColorMode.random)
            } label: {
                Text("color_mode_label")
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(Text("color_mode_label"))
        }
    }

    // MARK: - Player row

    private var playerRow: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.s) {
            Text("mint_player_row_title")
                .font(ToyMintFont.section)
                .foregroundColor(.mintCream.opacity(0.85))

            TextField(
                NSLocalizedString("player_name_placeholder", comment: "Name placeholder"),
                text: $playerName,
                prompt: Text(NSLocalizedString("player_name_placeholder", comment: "Name placeholder"))
                    .foregroundColor(.mintCream.opacity(0.55))
            )
            .textFieldStyle(MintFieldStyle())
            .focused($isPlayerNameFocused)
            .submitLabel(.done)
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)
            .accessibilityLabel(Text("player_name_label"))
            .accessibilityHint(Text("mint_player_hint"))

            Text("mint_player_optional_hint")
                .font(ToyMintFont.caption)
                .foregroundColor(.mintCream.opacity(0.7))
        }
    }

    // MARK: - Start button

    private var startButton: some View {
        Button {
            SoundManager.shared.playClick()
            handleStart()
        } label: {
            HStack(spacing: ToyMint.Spacing.s) {
                Image(systemName: "play.fill")
                    .accessibilityHidden(true)
                Text("start_game_button")
            }
        }
        .buttonStyle(MintPrimaryButtonStyle())
        .accessibilityLabel(Text("start_game_button"))
        .accessibilityHint(Text("mint_start_hint"))
    }

    private func handleStart() {
        let logic = createGameLogic()
        logic.displayRate = Int(shapeDisplayRate)

        var recipient = ""

        if isCryptoEnabled {
            let userAddress = playerWalletAddress.trimmingCharacters(in: .whitespacesAndNewlines)

            if userAddress.isEmpty {
                // Crypto enabled but no wallet entered — play without on-chain reward.
                // Falling back to the treasury address would cause a treasury→treasury
                // transfer that burns POL gas for zero net reward.
                recipient = ""
                web3Manager.statusMessage = NSLocalizedString(
                    "crypto_rewards_disabled",
                    comment: "Crypto Rewards Disabled"
                )
            } else {
                guard userAddress.hasPrefix("0x"), userAddress.count == 42 else {
                    web3Manager.statusMessage = NSLocalizedString(
                        "invalid_wallet_address",
                        comment: "Invalid Wallet Address"
                    )
                    return
                }
                recipient = userAddress
            }
        } else {
            recipient = ""
            web3Manager.statusMessage = NSLocalizedString(
                "crypto_rewards_disabled",
                comment: "Crypto Rewards Disabled"
            )
        }

        web3Manager.recipientAddress = recipient
        navigationPath.append(logic)
    }

    // MARK: - Rewards drawer

    private var rewardsDrawer: some View {
        MintDisclosureLade(
            title: "mint_rewards_title",
            subtitle: "mint_rewards_subtitle",
            isExpanded: $showRewardsLade
        ) {
            VStack(alignment: .leading, spacing: ToyMint.Spacing.m) {
                Toggle(isOn: $isCryptoEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("mint_rewards_toggle_label")
                            .font(ToyMintFont.body.weight(.semibold))
                            .foregroundColor(.mintCream)
                        Text("mint_rewards_toggle_hint")
                            .font(ToyMintFont.caption)
                            .foregroundColor(.mintCream.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(.mintCoral)
                .accessibilityHint(Text("mint_rewards_toggle_hint"))

                if isCryptoEnabled {
                    walletFields
                } else {
                    Text("mint_rewards_off_note")
                        .font(ToyMintFont.caption)
                        .foregroundColor(.mintCream.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    showDebugLog = true
                } label: {
                    HStack(spacing: ToyMint.Spacing.xs) {
                        Image(systemName: "wrench.and.screwdriver")
                            .accessibilityHidden(true)
                        Text("mint_technical_details")
                    }
                }
                .buttonStyle(MintGhostButtonStyle())
                .accessibilityLabel(Text("mint_technical_details"))
                .accessibilityHint(Text("mint_technical_details_hint"))
            }
            .padding(.top, ToyMint.Spacing.s)
        }
    }

    private var walletFields: some View {
        VStack(alignment: .leading, spacing: ToyMint.Spacing.s) {
            Text("wallet_address_label")
                .font(ToyMintFont.caption.weight(.semibold))
                .foregroundColor(.mintCream.opacity(0.8))

            TextField(
                NSLocalizedString("wallet_address_placeholder", comment: "0x..."),
                text: $playerWalletAddress,
                prompt: Text(NSLocalizedString("wallet_address_placeholder", comment: "0x..."))
                    .foregroundColor(.mintCream.opacity(0.5))
            )
            .textFieldStyle(MintFieldStyle())
            .font(.system(.body, design: .monospaced))
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .accessibilityLabel(Text("wallet_address_label"))
            .accessibilityHint(Text("mint_wallet_hint"))

            switch walletValidationState {
            case .empty:
                Text("mint_wallet_optional_note")
                    .font(ToyMintFont.caption)
                    .foregroundColor(.mintCream.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            case .valid:
                MintStatusLamp(state: .ok,
                               title: NSLocalizedString("mint_wallet_valid",
                                                        comment: "Valid Polygon address"),
                               systemImage: "checkmark.circle.fill")
            case .invalidFormat:
                MintStatusLamp(state: .warn,
                               title: NSLocalizedString("mint_wallet_invalid_inline",
                                                        comment: "Wallet must start with 0x and be 42 characters"),
                               systemImage: "exclamationmark.triangle.fill")
            }

            HStack(alignment: .top, spacing: ToyMint.Spacing.m) {
                MintStatusLamp(state: walletStatusLampState, title: walletStatusText)

                if !web3Manager.isConnected && !web3Manager.isLoading {
                    Button {
                        Task { await web3Manager.connect() }
                    } label: {
                        Text("connect_treasury_button")
                    }
                    .buttonStyle(MintSecondaryButtonStyle())
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Text("connect_treasury_button"))
                    .accessibilityHint(Text("mint_connect_treasury_hint"))
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        Text("mint_footer_credo")
            .font(ToyMintFont.caption)
            .foregroundColor(.mintCream.opacity(0.55))
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .padding(.top, ToyMint.Spacing.l)
    }

    // MARK: - Debug sheet

    private var debugLogSheet: some View {
        ZStack {
            ToyMintBackground()
            VStack(spacing: ToyMint.Spacing.l) {
                Text("mint_diagnostics_title")
                    .font(ToyMintFont.title)
                    .foregroundColor(.mintCreamBright)
                    .accessibilityAddTraits(.isHeader)

                ScrollView {
                    Text(web3Manager.debugLog.isEmpty
                         ? NSLocalizedString("mint_diagnostics_empty", comment: "No diagnostics yet")
                         : web3Manager.debugLog)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.mintCream)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .mintPanel(.petrol)

                Button {
                    showDebugLog = false
                } label: {
                    Text("mint_close_button")
                }
                .buttonStyle(MintSecondaryButtonStyle())
                .accessibilityLabel(Text("mint_close_button"))
            }
            .padding(ToyMint.Spacing.l)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func updateHighscore() {
        guard !playerName.isEmpty else {
            currentHighscore = 0
            return
        }
        currentHighscore = GameLogic.getHighScore(
            for: playerName,
            gameVersion: selectedGameVersion
        )
    }

    private func resetKeyboardTimer() {
        keyboardTimer?.invalidate()
        keyboardTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            DispatchQueue.main.async { isPlayerNameFocused = false }
        }
    }

    private func createGameLogic() -> GameLogic {
        GameLogic(
            gameTime: Int(gameDuration),
            gameVersion: selectedGameVersion,
            colorMode: selectedColorMode,
            displayRate: Int(shapeDisplayRate),
            player: playerName.isEmpty
                ? NSLocalizedString("player_name_label", comment: "Player Name Label")
                : playerName,
            numberOfShapes: Int(numberOfShapes)
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StartScreen(navigationPath: .constant(NavigationPath()))
    }
    .preferredColorScheme(.dark)
}
