import SwiftUI
import Combine

struct GameContainerView: View {
    private let shapeDisplayRate: Int
    @StateObject private var gameTimer: GameTimer
    @State private var gameLogic: GameLogic
    @State private var shapeCounts: [ShapeType: Int]
    @State private var colorMode: ColorMode
    @State private var currentShape: ShapeType?
    @State private var goToEndScreen = false
    @Binding var navigationPath: NavigationPath

    init(gameLogic: GameLogic, navigationPath: Binding<NavigationPath>) {
        self._gameLogic = State(initialValue: gameLogic)
        self.shapeDisplayRate = gameLogic.displayRate
        self._gameTimer = StateObject(wrappedValue: GameTimer(gameTime: gameLogic.gameTime, displayRate: gameLogic.displayRate))
        self._shapeCounts = State(initialValue: Dictionary(uniqueKeysWithValues: ShapeType.allCases.map { ($0, 0) }))
        self._colorMode = State(initialValue: gameLogic.colorMode)
        self._navigationPath = navigationPath
    }

    var body: some View {
        VStack {
            Text("Spelscherm")
                .font(.largeTitle)
                .padding()

            Text("Resterende tijd: \(gameTimer.remainingTime) seconden")
                .font(.title2)
                .padding()

            if let shape = currentShape {
                shape.shapeView()
                    .foregroundColor(colorMode == .random ? .random() : shape.color)
                    .frame(width: 100, height: 100)
            }

            EmptyView()
                .onChange(of: goToEndScreen) { newValue in
                    if newValue {
                        navigationPath.append("endscreen")
                    }
                }
        }
        .onAppear {
            gameTimer.stop()
            gameTimer.reset(gameTime: gameLogic.gameTime, displayRate: gameLogic.displayRate)
            gameTimer.start {
                let newShape = GameLogic.getRandomShape(shapes: gameLogic.shapeType, excluding: currentShape)
                currentShape = newShape
                shapeCounts[newShape, default: 0] += 1
            }
        }
        .onChange(of: gameTimer.isRunning) { isRunning in
            if !isRunning {
                goToEndScreen = true
            }
        }
        .onDisappear {
            gameTimer.stop()
        }
        .navigationDestination(for: String.self) { value in
            if value == "endscreen" {
                EndScreen(
                    shapeCounts: $shapeCounts,
                    dismissAction: { navigationPath.removeLast() },
                    restartAction: { navigationPath.removeLast() },
                    gameLogic: $gameLogic,
                    navigationPath: $navigationPath
                )
            }
        }
    }
}

