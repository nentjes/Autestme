import SwiftUI
import Combine

/// De hoofdview voor het spelen van het spel
struct GameContainerView: View {
    /// Het interval tussen het tonen van vormen in seconden
    private let shapeDisplayRate: Int
    @StateObject private var gameTimer: GameTimer
    @State private var gameLogic: GameLogic
    @State private var showEndScreen = false
    /// Het aantal keer dat elke vorm is getoond
    @State private var shapeCounts: [ShapeType: Int]
    /// De gekozen kleurmodus
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
            // Titel van het spel
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
            
            // Navigatie naar het eindscherm
            NavigationLink(
                destination: EndScreen(
                    shapeCounts: $shapeCounts,
                    dismissAction: { showEndScreen = false },
                    restartAction: { showEndScreen = false },
                    gameLogic: $gameLogic
                ),
                isActive: $showEndScreen
            ) {
                Text("Ga naar eindscherm")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .onAppear {
            gameTimer.start { 
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

