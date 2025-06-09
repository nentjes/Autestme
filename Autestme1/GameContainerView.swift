import SwiftUI
import Combine

/// De hoofdview voor het spelen van het spel
struct GameContainerView: View {
    /// Het interval tussen het tonen van vormen in seconden
    private let shapeDisplayRate: Int
    /// De timer die het spel beheert
    @StateObject private var gameTimer: GameTimer
    /// De logica van het spel
    @State private var gameLogic: GameLogic
    /// Of het eindscherm getoond moet worden
    @State private var showEndScreen = false
    /// Het aantal keer dat elke vorm is getoond
    @State private var shapeCounts: [ShapeType: Int]
    /// De gekozen kleurmodus
    @State private var colorMode: ColorMode
    /// De huidige vorm die getoond wordt
    @State private var currentShape: ShapeType?
    /// Geschiedenis van de laatste getoonde vormen
    @State private var shapeHistory: [ShapeType] = []
    /// Maximum aantal vormen in de geschiedenis
    private let maxHistoryCount = 3

    /// Initialiseert een nieuwe GameContainerView
    /// - Parameters:
    ///   - gameLogic: De logica van het spel
    ///   - shapeDisplayRate: Het interval tussen het tonen van vormen in seconden
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
            
            // Toont de resterende tijd
            Text("Resterende tijd: \(gameTimer.remainingTime) seconden")
                .font(.title2)
                .padding()
            
            // Toont de huidige vorm
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
                EmptyView()
            }
        }
        .onAppear {
            // Start het spel en begin met het tonen van vormen
            gameTimer.start { [weak gameLogic] in
                guard let gameLogic = gameLogic else { return }
                
                // Update de geschiedenis
                if let currentShape = currentShape {
                    shapeHistory.append(currentShape)
                    if shapeHistory.count > maxHistoryCount {
                        shapeHistory.removeFirst()
                    }
                }
                
                // Kies een nieuwe vorm
                let newShape = GameLogic.getRandomShape(
                    shapes: gameLogic.shapeType,
                    excluding: currentShape,
                    lastShapes: shapeHistory
                )
                
                currentShape = newShape
                shapeCounts[newShape, default: 0] += 1
            }
        }
        .onChange(of: gameTimer.isRunning) { isRunning in
            // Toon het eindscherm wanneer de timer stopt
            if !isRunning {
                showEndScreen = true
            }
        }
        .onDisappear {
            // Stop de timer wanneer de view verdwijnt
            gameTimer.stop()
        }
    }
}

