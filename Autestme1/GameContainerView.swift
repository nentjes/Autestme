import SwiftUI
import Combine

struct GameContainerView: View {
    private let shapeDisplayRate: Int
    @State private var gameLogic: GameLogic
    @State private var remainingTime: Int
    @State private var timerCancellable: AnyCancellable?
    @State private var showEndScreen = false
    @State private var shapeCounts: [ShapeType: Int]
    @State private var colorMode: ColorMode

    init(gameLogic: GameLogic, shapeDisplayRate: Int = 1, remainingTime: Int = 60) {
        self._gameLogic = State(initialValue: gameLogic)
        self.shapeDisplayRate = shapeDisplayRate
        self._remainingTime = State(initialValue: remainingTime)
        self._shapeCounts = State(initialValue: Dictionary(uniqueKeysWithValues: ShapeType.allCases.map { ($0, 0) }))
        self._colorMode = State(initialValue: gameLogic.colorMode)
    }

    var body: some View {
        VStack {
            Text("Spelscherm")
                .font(.largeTitle)
                .padding()
            
            Text("Resterende tijd: \(remainingTime) seconden")
                .font(.title2)
                .padding()
            
            ShapeDisplayView(shapes: gameLogic.shapeType, displayRate: shapeDisplayRate, colorMode: colorMode, shapeCounts: $shapeCounts)
            
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
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if remainingTime > 0 {
                        remainingTime -= 1
                    } else {
                        timerCancellable?.cancel()
                        showEndScreen = true
                    }
                }
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
    }
}

