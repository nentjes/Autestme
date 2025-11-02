import SwiftUI

struct StartScreen: View {
    @Binding var navigationPath: NavigationPath

    @State private var gameDuration: Double = 10
    @State private var numberOfShapes: Double = 3
    @State private var shapeDisplayRate: Double = 1
    @State private var selectedColorMode: ColorMode = .fixed
    @State private var showInfoAlert = false
    @State private var selectedGameVersion: GameVersion = .shapes
    @State private var playerName: String = ""
    @State private var currentHighscore: Int = 0

    // HIER: Deze helper-functie haalt nu de vertaalde strings op
    var labelForType: String {
        let key: String
        switch selectedGameVersion {
        case .shapes: key = "item_type_shapes"
        case .numbers: key = "item_type_numbers"
        case .letters: key = "item_type_letters"
        }
        // Haal de vertaalde string op uit je .strings bestand
        return NSLocalizedString(key, comment: "Game type label for item counter")
    }

    var rangeForType: ClosedRange<Double> {
        switch selectedGameVersion {
        case .shapes: return 1...Double(ShapeType.allCases.count)
        case .numbers: return 1...10
        case .letters: return 1...26
        }
    }

    // HIER: Deze helper-functie laadt de highscore
    private func updateHighscore() {
        // Gebruikt dezelfde logica als bij het aanmaken van het spel
        let name = playerName.isEmpty ? "Speler" : playerName // "Speler" kun je ook lokaliseren
        currentHighscore = GameLogic.getHighScore(for: name, gameVersion: selectedGameVersion)
    }

    private func createGameLogic() -> GameLogic {
        return GameLogic(
            gameTime: Int(gameDuration),
            gameVersion: selectedGameVersion,
            colorMode: selectedColorMode,
            displayRate: Int(shapeDisplayRate),
            player: playerName.isEmpty ? "Speler" : playerName,
            numberOfShapes: Int(numberOfShapes)
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("app_title") // <-- Gelokaliseerd
                        .font(.largeTitle)
                        .bold()

                    Button(action: { showInfoAlert = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }

                Group {
                    Text("player_name_label") // <-- Gelokaliseerd
                    
                    TextField("player_name_placeholder", text: $playerName) // <-- Gelokaliseerd
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    // HIER: Highscore logica met lokalisatie
                    if currentHighscore > 0 {
                        Text(String(format: NSLocalizedString("highscore_display", comment: ""), "\(currentHighscore)"))
                    } else {
                        Text("no_highscore")
                    }

                }

                Group {
                    Text(String(format: NSLocalizedString("game_duration_label", comment: ""), "\(Int(gameDuration))"))
                    Slider(value: $gameDuration, in: 5...30)

                    Text(String(format: NSLocalizedString("game_speed_label", comment: ""), "\(Int(shapeDisplayRate))"))
                    Slider(value: $shapeDisplayRate, in: 1...10)

                    Text("color_mode_label") // <-- Gelokaliseerd
                    Picker("Kleurmodus", selection: $selectedColorMode) {
                        Text("color_mode_fixed").tag(ColorMode.fixed) // <-- Gelokaliseerd
                        Text("color_mode_random").tag(ColorMode.random) // <-- Gelokaliseerd
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Text("game_type_label") // <-- Gelokaliseerd
                    Picker("Speltype", selection: $selectedGameVersion) {
                        Text("game_type_shapes").tag(GameVersion.shapes) // <-- Gelokaliseerd
                        Text("game_type_letters").tag(GameVersion.letters) // <-- Gelokaliseerd
                        Text("game_type_numbers").tag(GameVersion.numbers) // <-- Gelokaliseerd
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Text(String(format: NSLocalizedString("item_count_label", comment: ""), labelForType, "\(Int(numberOfShapes))"))
                    Slider(value: $numberOfShapes, in: rangeForType, step: 1)
                }

                Button(action: {
                    let logic = createGameLogic()
                    logic.displayRate = Int(shapeDisplayRate)
                    navigationPath.append(logic)
                }) {
                    Text("start_game_button") // <-- Gelokaliseerd
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
        }
        // HIER: De .onChange en .onAppear die de highscore verversen
        .onAppear {
            updateHighscore()
        }
        .onChange(of: playerName) { _ in
            updateHighscore()
        }
        .onChange(of: selectedGameVersion) { _ in
            updateHighscore()
        }
        // HIER: De gelokaliseerde alert
        .alert(Text("info_title"), isPresented: $showInfoAlert) {
            Button("alert_button_ok") { }
        } message: {
            Text("info_body")
        }
        .navigationDestination(for: GameLogic.self) { logic in
            GameContainerView(gameLogic: logic, navigationPath: $navigationPath)
        }
    }
}
