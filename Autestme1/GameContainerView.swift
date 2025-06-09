import SwiftUI
import Combine

struct GameContainerView: View {
    private let shapeDisplayRate: Int
    @StateObject private var gameTimer: GameTimer
    @State private var gameLogic: GameLogic
    @State private var showEndScreen = false
    @State private var shapeCounts: [ShapeType: Int]
    @State private var colorMode: ColorMode
    @State private var currentShape: ShapeType?

    init(gameLogic: GameLogic, shapeDisplayRate: Int = 1) {
        self._gameLogic = State(initialValue: gameLogic)
        self.shapeDisplayRate = shapeDisplayRate
        self._gameTimer = StateObject(wrappedValue: GameTimer(gameTime: gameLogic.gameTime, displayRate: shapeDisplayRate))
        self._shapeCounts = State(initialValue: Dictionary(uniqueKeysWithValues: ShapeType.allCases.map { ($0, 0) }))
        self._colorMode = State(initialValue: gameLogic.colorMode)
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
            
            NavigationLink(
                destination: EndScreen(
                    shapeCounts: $shapeCounts,
                    dismissAction: { showEndScreen = false },
                    restartAction: { showEndScreen = false },
                    gameLogic: $gameLogic
                ),
                isActive: $showEndScreen
            ) {
                EmptyView()
            }
        }
        .onAppear {
            gameTimer.start { [weak gameLogic] in
                guard let gameLogic = gameLogic else { return }
                let newShape = GameLogic.getRandomShape(shapes: gameLogic.shapeType, excluding: currentShape)
                currentShape = newShape
                shapeCounts[newShape, default: 0] += 1
            }
        }
        .onChange(of: gameTimer.isRunning) { isRunning in
            if !isRunning {
                showEndScreen = true
            }
        }
        .onDisappear {
            gameTimer.stop()
        }
    }
}

