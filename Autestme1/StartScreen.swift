import SwiftUI

struct StartScreen: View {
    @Binding var navigationPath: NavigationPath

    // WEB3 ADDITION
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
    
    // NEW: User's wallet address for receiving rewards
    @State private var playerWalletAddress: String = ""

    var labelForType: String {
        let key: String
        switch selectedGameVersion {
        case .shapes: key = "item_type_shapes"
        case .numbers: key = "item_type_numbers"
        case .letters: key = "item_type_letters"
        }
        return NSLocalizedString(key, comment: "Game type label for item counter")
    }

    var rangeForType: ClosedRange<Double> {
        switch selectedGameVersion {
        case .shapes: return 1...Double(ShapeType.allCases.count)
        case .numbers: return 1...10
        case .letters: return 1...26
        }
    }

    private func updateHighscore() {
        let name = playerName.isEmpty ? NSLocalizedString("Player", comment: "") : playerName
        currentHighscore = GameLogic.getHighScore(for: name, gameVersion: selectedGameVersion)
    }

    private func createGameLogic() -> GameLogic {
        // The logic here simply creates the GameLogic object
        return GameLogic(
            gameTime: Int(gameDuration),
            gameVersion: selectedGameVersion,
            colorMode: selectedColorMode,
            displayRate: Int(shapeDisplayRate),
            player: playerName.isEmpty ? NSLocalizedString("Player", comment: "") : playerName,
            numberOfShapes: Int(numberOfShapes)
        )
    }

    // --- MAIN BODY REFACTORED ---
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                walletSection
                titleSection
                playerSection
                settingsSection
                startButtonSection
            }
            .padding()
        }
        .onAppear {
            updateHighscore()
            // Reset status on load
            if !web3Manager.isConnected {
                 web3Manager.statusMessage = "Ready to connect"
            }
        }
        .onChange(of: playerName) { _ in
            updateHighscore()
        }
        .onChange(of: selectedGameVersion) { _ in
            updateHighscore()
        }
        .sheet(isPresented: $showDebugLog) {
            debugLogSheet
        }
        .alert(Text("info_title"), isPresented: $showInfoAlert) {
            Button("alert_button_ok") { }
        } message: {
            Text("info_body")
        }
        .navigationDestination(for: GameLogic.self) { logic in
            GameContainerView(gameLogic: logic, navigationPath: $navigationPath)
        }
    }
    
    // --- REFACTORED SUB-VIEWS START HERE ---

    // 1. WALLET INPUT AND STATUS SECTION (Replaces lines 60-95 in original file)
    private var walletSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            
            // Input Field
            Group {
                Text("PLAYER WALLET ADDRESS (Polygon Amoy)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextField("0x... (Paste your MetaMask Address)", text: $playerWalletAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            // Status and Connect Buttons
            HStack {
                // WEB3 STATUS
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
                
                // LOG BUTTON
                Button(action: { showDebugLog = true }) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .foregroundColor(.blue)
                }
                .padding(.trailing, 5)
                
                if !web3Manager.isConnected {
                    Button(action: {
                        Task {
                            await web3Manager.connect()
                        }
                    }) {
                        Text("Connect") // <-- NL: Verbind
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.bottom, 10)
    }
    
    // 2. TITLE SECTION
    private var titleSection: some View {
        HStack {
            Text("app_title")
                .font(.largeTitle)
                .bold()

            Button(action: { showInfoAlert = true }) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
    }

    // 3. PLAYER NAME AND HIGHSCORE SECTION
    private var playerSection: some View {
        Group {
            Text("player_name_label")
            
            TextField("player_name_placeholder", text: $playerName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if currentHighscore > 0 {
                Text(
                    String(
                        format: NSLocalizedString("highscore_display", comment: ""),
                        "\(currentHighscore)"
                    )
                )
            } else {
                Text("no_highscore")
            }
        }
    }
    
    // 4. GAME SETTINGS (Sliders and Pickers)
    private var settingsSection: some View {
        Group {
            Text(
                String(
                    format: NSLocalizedString("game_duration_label", comment: ""),
                    "\(Int(gameDuration))"
                )
            )
            Slider(value: $gameDuration, in: 5...30)

            Text(
                String(
                    format: NSLocalizedString("game_speed_label", comment: ""),
                    "\(Int(shapeDisplayRate))"
                )
            )
            Slider(value: $shapeDisplayRate, in: 1...10)

            Text("color_mode_label")
            Picker("Color Mode", selection: $selectedColorMode) { // NL: Kleurmodus
                Text("color_mode_fixed").tag(ColorMode.fixed)
                Text("color_mode_random").tag(ColorMode.random)
            }
            .pickerStyle(SegmentedPickerStyle())

            Text("game_type_label")
            Picker("Game Type", selection: $selectedGameVersion) { // NL: Speltype
                Text("game_type_shapes").tag(GameVersion.shapes)
                Text("game_type_letters").tag(GameVersion.letters)
                Text("game_type_numbers").tag(GameVersion.numbers)
            }
            .pickerStyle(SegmentedPickerStyle())

            Text(
                String(
                    format: NSLocalizedString("item_count_label", comment: ""),
                    labelForType,
                    "\(Int(numberOfShapes))"
                )
            )
            Slider(value: $numberOfShapes, in: rangeForType, step: 1)
        }
    }
    
    // 5. START BUTTON SECTION
    private var startButtonSection: some View {
        Button(action: {
            let logic = createGameLogic()
            logic.displayRate = Int(shapeDisplayRate)

            // Validation: Ensure an address is provided and is valid
            guard playerWalletAddress.hasPrefix("0x"),
                  playerWalletAddress.count == 42 else {
                web3Manager.statusMessage = "❌ Invalid Wallet Address."
                return
            }

            // Store wallet address temporarily in Web3Manager for access by EndScreen
            web3Manager.recipientAddress = playerWalletAddress
            
            navigationPath.append(logic)
        }) {
            Text("start_game_button")
                .font(.title2)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    // 6. DEBUG SHEET
    private var debugLogSheet: some View {
        VStack {
            Text("Diagnostic Log") // NL: Diagnose Logboek
                .font(.headline)
                .padding()
            
            ScrollView {
                Text(web3Manager.debugLog)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Button("Close") { showDebugLog = false } // NL: Sluit
                .padding()
        }
    }
}
