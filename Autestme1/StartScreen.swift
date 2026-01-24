import SwiftUI

struct StartScreen: View {
    @Binding var navigationPath: NavigationPath

    // Web3 singleton
    @ObservedObject private var web3Manager = Web3Manager.shared

    @State private var gameDuration: Double = 5
    @State private var numberOfShapes: Double = 2
    @State private var shapeDisplayRate: Double = 3
    @State private var selectedColorMode: ColorMode = .fixed
    @State private var showInfoAlert = false
    @State private var showDebugLog = false
    @State private var selectedGameVersion: GameVersion = .shapes
    @State private var playerName: String = ""
    @State private var currentHighscore: Int = 0
    
    // Wallet address of the player (Polygon Mainnet)
    @State private var playerWalletAddress: String = ""
    
    // NEW: State for conditional crypto visibility
    @State private var isCryptoEnabled: Bool = false
    @State private var showSwipeTip: Bool = true
    
    // NEW: Persistent state to track if user has ever swiped to show the full instruction only once
    @AppStorage("hasSeenCryptoSwipe") private var hasSeenCryptoSwipe: Bool = false


    // Label for slider
    var labelForType: String {
        let key: String
        switch selectedGameVersion {
        case .shapes: key = "item_type_shapes"
        case .numbers: key = "item_type_numbers"
        case .letters: key = "item_type_letters"
        }
        return NSLocalizedString(key, comment: "Game type label for item counter")
    }

    // Range for number of items
    var rangeForType: ClosedRange<Double> {
        switch selectedGameVersion {
        case .shapes: return 1...Double(ShapeType.allCases.count)
        case .numbers: return 1...10
        case .letters: return 1...26
        }
    }

    private func updateHighscore() {
        let name = playerName.isEmpty ? NSLocalizedString("Naam speler:", comment: "Player Name Label") : playerName
        currentHighscore = GameLogic.getHighScore(for: name, gameVersion: selectedGameVersion)
    }

    private func createGameLogic() -> GameLogic {
        GameLogic(
            gameTime: Int(gameDuration),
            gameVersion: selectedGameVersion,
            colorMode: selectedColorMode,
            displayRate: Int(shapeDisplayRate),
            player: playerName.isEmpty ? NSLocalizedString("Naam speler:", comment: "Player Name Label") : playerName,
            numberOfShapes: Int(numberOfShapes)
        )
    }

    // --- BODY ---
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Conditional Wallet Section
                if isCryptoEnabled {
                    walletSection
                } else if showSwipeTip {
                    swipeInstruction
                }
                
                titleSection
                playerSection
                settingsSection
                startButtonSection
            }
            .padding()
        }
        .onAppear {
            updateHighscore()
            // Connect to Web3 in background - don't block UI
            if !web3Manager.isConnected && !web3Manager.isLoading {
                Task {
                    await web3Manager.connect()
                }
            }
        }
        .onChange(of: playerName) { _ in updateHighscore() }
        .onChange(of: selectedGameVersion) { _ in updateHighscore() }
        .sheet(isPresented: $showDebugLog) {
            debugLogSheet
        }
        // CORRECTED: Ensure Text concatenation works by explicitly combining them
        .alert(Text(NSLocalizedString("info_title", comment: "Alert Title")), isPresented: $showInfoAlert) {
            Button(NSLocalizedString("alert_button_ok", comment: "OK button")) { }
        } message: {
            // Combine the standard game info and the crypto info here
            // Using String(localized:...) to avoid Canvas preview errors
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
        // MODIFIED: Swipe Gesture - use simultaneousGesture to not block scrolling/taps
        .simultaneousGesture(
            DragGesture(minimumDistance: 100, coordinateSpace: .local)
                .onEnded { value in
                    // Only trigger on horizontal swipes (not vertical scrolling)
                    let horizontalAmount = abs(value.translation.width)
                    let verticalAmount = abs(value.translation.height)
                    guard horizontalAmount > verticalAmount else { return }

                    withAnimation {
                        // Swipe right-to-left (to enable crypto)
                        if value.translation.width < -100 {
                            isCryptoEnabled = true
                            showSwipeTip = false
                            // Mark as seen once the user successfully performs the swipe
                            hasSeenCryptoSwipe = true
                        }
                        // Swipe left-to-right (to disable crypto)
                        else if value.translation.width > 100 && isCryptoEnabled {
                            isCryptoEnabled = false
                            showSwipeTip = true
                            playerWalletAddress = "" // Clear address when hiding
                        }
                    }
                }
        )
    }
    
    // --- SUBVIEWS ---
    
    // MODIFIED: Swipe Instruction View now checks hasSeenCryptoSwipe
    private var swipeInstruction: some View {
        HStack(alignment: .top) {
            Image(systemName: "hand.point.left.fill")
                .font(.title)
                .foregroundColor(.indigo)
                // NEW: Subtle repeated animation for the first time
                .scaleEffect(hasSeenCryptoSwipe ? 1.0 : 1.1)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: hasSeenCryptoSwipe
                )

            
            VStack(alignment: .leading) {
                Text(NSLocalizedString("swipe_instruction_bold", comment: "Swipe instruction bold part"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                
                // Show the full body only if the user has NOT swiped yet
                if !hasSeenCryptoSwipe {
                    Text(NSLocalizedString("swipe_instruction_body", comment: "Swipe instruction body part"))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(12)
        .padding(.bottom, 10)
    }

    // 1. Wallet input + Web3 status
    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(NSLocalizedString("wallet_address_label", comment: "WALLET ADDRESS FOR REWARDS"))
                .font(.caption)
                .foregroundColor(.gray)
            
            // User input field
            TextField(NSLocalizedString("wallet_address_placeholder", comment: "0x..."), text: $playerWalletAddress)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .accessibilityLabel("Wallet address")
                .accessibilityHint("Enter your Polygon wallet address for rewards")
            
            // Default Wallet Information
            HStack {
                Text(NSLocalizedString("default_recipient_label", comment: "Default Recipient:"))
                    .font(.caption)
                Text(web3Manager.defaultRecipientAddress.isEmpty ? NSLocalizedString("Verbinden...", comment: "Connecting...") : web3Manager.defaultRecipientAddress.prefix(6) + "...")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                // Button to easily fill in the default address
                Button(action: { playerWalletAddress = web3Manager.defaultRecipientAddress }) {
                    Text(NSLocalizedString("use_default_button", comment: "Use Default"))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                .accessibilityLabel("Use default wallet")
                .accessibilityHint("Fill in the default treasury wallet address")
            }


            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(web3Manager.isConnected ? .green : .orange)
                    .font(.title2)
                
                if web3Manager.isLoading {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Text(web3Manager.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: { showDebugLog = true }) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Show debug log")
                .accessibilityHint("View blockchain connection diagnostics")
                .padding(.trailing, 5)
                
                // Treasury Connection Button (only visible if not connected)
                if !web3Manager.isConnected {
                    Button(action: {
                        Task {
                            await web3Manager.connect()
                        }
                    }) {
                        Text(NSLocalizedString("connect_treasury_button", comment: "Connect Treasury"))
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .accessibilityLabel("Connect to treasury")
                    .accessibilityHint("Connect to the blockchain treasury wallet")
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.bottom, 10)
    }
    
    // 2. Title
    private var titleSection: some View {
        HStack {
            Text(NSLocalizedString("app_title", comment: "App Title"))
                .font(.largeTitle)
                .bold()

            Button(action: { showInfoAlert = true }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
            .accessibilityLabel("Game information")
            .accessibilityHint("Show game rules and crypto rewards information")
        }
    }

    // 3. Player Name + Highscore
    private var playerSection: some View {
        Group {
            Text(NSLocalizedString("player_name_label", comment: "Player Name Label"))
            
            TextField(NSLocalizedString("player_name_placeholder", comment: "Name Placeholder"), text: $playerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .accessibilityLabel("Player name")
                .accessibilityHint("Enter your name to track high scores")
            
            if currentHighscore > 0 {
                Text(
                    String(
                        format: NSLocalizedString("highscore_display", comment: "Highscore Display"),
                        "\(currentHighscore)"
                    )
                )
            } else {
                Text(NSLocalizedString("no_highscore", comment: "No Highscore"))
            }
        }
    }
    
    // 4. Game settings
    private var settingsSection: some View {
        Group {
            Text(
                String(
                    format: NSLocalizedString("game_duration_label", comment: "Game Duration Label"),
                    "\(Int(gameDuration))"
                )
            )
            Slider(value: $gameDuration, in: 5...30)
                .accessibilityLabel("Game duration")
                .accessibilityValue("\(Int(gameDuration)) seconds")

            Text(
                String(
                    format: NSLocalizedString("game_speed_label", comment: "Game Speed Label"),
                    "\(Int(shapeDisplayRate))"
                )
            )
            Slider(value: $shapeDisplayRate, in: 1...10)
                .accessibilityLabel("Display speed")
                .accessibilityValue("\(Int(shapeDisplayRate)) items per second")

            Text(NSLocalizedString("color_mode_label", comment: "Color Mode Label"))
            Picker(NSLocalizedString("Color mode", comment: "Color Mode Picker Label"), selection: $selectedColorMode)
            {
                Text(NSLocalizedString("color_mode_fixed", comment: "Fixed")).tag(ColorMode.fixed)
                Text(NSLocalizedString("color_mode_random", comment: "Random")).tag(ColorMode.random)
            }
            .pickerStyle(SegmentedPickerStyle())
            .accessibilityLabel("Color mode")

            Text(NSLocalizedString("game_type_label", comment: "Game Type Label"))
            Picker(NSLocalizedString("Game type", comment: "Game Type Picker Label"), selection: $selectedGameVersion)
            {
                Text(NSLocalizedString("game_type_shapes", comment: "Shapes")).tag(GameVersion.shapes)
                Text(NSLocalizedString("game_type_letters", comment: "Letters")).tag(GameVersion.letters)
                Text(NSLocalizedString("game_type_numbers", comment: "Numbers")).tag(GameVersion.numbers)
            }
            .pickerStyle(SegmentedPickerStyle())
            .accessibilityLabel("Game type")

            Text(
                String(
                    format: NSLocalizedString("item_count_label", comment: "Item Count Label"),
                    labelForType,
                    "\(Int(numberOfShapes))"
                )
            )
            Slider(value: $numberOfShapes, in: rangeForType, step: 1)
                .accessibilityLabel("Number of items")
                .accessibilityValue("\(Int(numberOfShapes)) \(labelForType)")
        }
    }

    // 5. Start button
    private var startButtonSection: some View {
        Button(action: {
            let logic = createGameLogic()
            logic.displayRate = Int(shapeDisplayRate)
            
            var recipient = ""

            if isCryptoEnabled {
                let userAddress = playerWalletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if userAddress.isEmpty {
                    // Scenario 2: User swiped, but left the field empty -> use default app wallet
                    if web3Manager.defaultRecipientAddress.isEmpty {
                        web3Manager.statusMessage = NSLocalizedString("default_wallet_error", comment: "Default Wallet Error")
                        return
                    }
                    recipient = web3Manager.defaultRecipientAddress
                    web3Manager.statusMessage = NSLocalizedString("default_wallet_configured", comment: "Default Wallet Configured")
                } else {
                    // Scenario 1: User swiped and entered an address -> validate and use it
                    guard userAddress.hasPrefix("0x"), userAddress.count == 42 else {
                        web3Manager.statusMessage = NSLocalizedString("invalid_wallet_address", comment: "Invalid Wallet Address")
                        return
                    }
                    recipient = userAddress
                }
            } else {
                // Scenario 3: Crypto disabled -> rewards are completely skipped
                recipient = ""
                web3Manager.statusMessage = NSLocalizedString("crypto_rewards_disabled", comment: "Crypto Rewards Disabled")
            }

            // Save the recipient address to Web3Manager. EndScreen checks this string.
            web3Manager.recipientAddress = recipient
            
            navigationPath.append(logic)
        }) {
            Text(NSLocalizedString("start_game_button", comment: "Start Game Button"))
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .accessibilityLabel("Start game")
        .accessibilityHint("Begin the memory game with current settings")
    }

    // 6. Debug sheet
    private var debugLogSheet: some View {
        VStack {
            Text(NSLocalizedString("Diagnostics Log", comment: "Diagnostics Log Title"))
                .font(.headline)
                .padding()
            
            ScrollView {
                Text(web3Manager.debugLog)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button(NSLocalizedString("Close", comment: "Close Button")) { showDebugLog = false }
                .padding()
        }
    }
}

// MARK: - Preview Provider
#Preview {
    // To initialize @Binding correctly, we use .constant()
    // Web3Manager.shared is used automatically.
    StartScreen(navigationPath: .constant(NavigationPath()))
        .preferredColorScheme(.light) // Optional: Default light theme in preview
}
