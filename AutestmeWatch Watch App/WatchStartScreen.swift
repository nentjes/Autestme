import SwiftUI

struct WatchStartScreen: View {
    @State private var gameDuration: Int = 5
    @State private var numberOfShapes: Int = 2
    @State private var displayRate: Int = 2
    @State private var colorMode: WatchColorMode = .fixed
    @State private var navigationPath = NavigationPath()
    @State private var gameLogic: WatchGameLogic?

    private var currentHighscore: Int {
        WatchGameLogic.getHighScore()
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Section {
                    Text(NSLocalizedString("app_title", comment: ""))
                        .font(.headline)

                    if currentHighscore > 0 {
                        Text(String(
                            format: NSLocalizedString("highscore_display", comment: ""),
                            "\(currentHighscore)"
                        ))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }

                Section {
                    Stepper(value: $gameDuration, in: 5...15) {
                        Text(String(
                            format: NSLocalizedString("game_duration_label", comment: ""),
                            "\(gameDuration)"
                        ))
                        .font(.caption2)
                    }

                    Stepper(value: $displayRate, in: 1...5) {
                        Text(String(
                            format: NSLocalizedString("game_speed_label", comment: ""),
                            "\(displayRate)"
                        ))
                        .font(.caption2)
                    }

                    Stepper(value: $numberOfShapes, in: 1...WatchShapeType.allCases.count) {
                        Text(String(
                            format: NSLocalizedString("item_count_label", comment: ""),
                            NSLocalizedString("item_type_shapes", comment: ""),
                            "\(numberOfShapes)"
                        ))
                        .font(.caption2)
                    }

                    Picker(selection: $colorMode) {
                        Text(NSLocalizedString("color_mode_fixed", comment: "")).tag(WatchColorMode.fixed)
                        Text(NSLocalizedString("color_mode_random", comment: "")).tag(WatchColorMode.random)
                    } label: {
                        Text(NSLocalizedString("color_mode_label", comment: ""))
                            .font(.footnote)
                    }
                }

                Section {
                    Button(action: startGame) {
                        Text(NSLocalizedString("start_game_button", comment: ""))
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .listItemTint(.blue)
                }
            }
            .navigationDestination(for: String.self) { value in
                if value == "game", let logic = gameLogic {
                    WatchGameView(gameLogic: logic, navigationPath: $navigationPath)
                }
            }
        }
    }

    private func startGame() {
        let logic = WatchGameLogic(
            gameTime: gameDuration,
            colorMode: colorMode,
            displayRate: displayRate,
            numberOfShapes: numberOfShapes
        )
        gameLogic = logic
        navigationPath.append("game")
    }
}

#Preview {
    WatchStartScreen()
}
