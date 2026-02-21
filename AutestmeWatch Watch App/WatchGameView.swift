import SwiftUI
import WatchKit

struct WatchGameView: View {
    @ObservedObject var gameLogic: WatchGameLogic
    @Binding var navigationPath: NavigationPath
    @StateObject private var gameTimer: WatchGameTimer
    @State private var currentShape: WatchShapeType?
    @State private var shapeCounts: [WatchShapeType: Int] = [:]
    @State private var navigateToEnd = false

    init(gameLogic: WatchGameLogic, navigationPath: Binding<NavigationPath>) {
        self.gameLogic = gameLogic
        self._navigationPath = navigationPath
        self._gameTimer = StateObject(wrappedValue: WatchGameTimer(
            gameTime: gameLogic.gameTime,
            displayRate: gameLogic.displayRate
        ))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Timer bar
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                Text("\(gameTimer.remainingTime)s")
                    .font(.title3)
                    .monospacedDigit()
            }

            Spacer()

            // Shape display area
            if let shape = currentShape {
                shape.shapeView()
                    .foregroundColor(
                        gameLogic.colorMode == .random ? .watchRandom() : shape.color
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(shape.displayName)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Initialize counts
            for shape in WatchShapeType.allCases {
                shapeCounts[shape] = 0
            }

            // Show first shape
            let first = WatchGameLogic.getRandomShape(from: gameLogic.shapeTypes)
            currentShape = first
            shapeCounts[first, default: 0] += 1
            first.playHaptic()

            // Start timer
            gameTimer.start {
                let newShape = WatchGameLogic.getRandomShape(
                    from: gameLogic.shapeTypes,
                    excluding: currentShape
                )
                currentShape = newShape
                shapeCounts[newShape, default: 0] += 1
                newShape.playHaptic()
            }
        }
        .onChange(of: gameTimer.isRunning) { isRunning in
            if !isRunning {
                // Copy counts to gameLogic
                gameLogic.shapeCounts = shapeCounts
                navigateToEnd = true
            }
        }
        .onDisappear {
            gameTimer.stop()
        }
        .navigationDestination(isPresented: $navigateToEnd) {
            WatchEndScreen(gameLogic: gameLogic, shapeCounts: shapeCounts, navigationPath: $navigationPath)
        }
    }
}
