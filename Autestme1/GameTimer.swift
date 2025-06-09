import Foundation
import SwiftUI
import Combine

// 1. Protocol voor game logic
protocol GameLogicProtocol {
    var score: Int { get }
    var remainingTime: Int { get }
    func reset()
    func updateScore()
}

// 2. Betere error handling
enum GameError: Error {
    case invalidGameState
    case invalidPlayerName
    case invalidGameTime
}

// 3. Verbeterde state management
class GameState: ObservableObject {
    @Published private(set) var score: Int = 0
    @Published private(set) var remainingTime: Int = 0
    @Published private(set) var isGameActive: Bool = false
    
    func startGame() throws {
        guard remainingTime > 0 else {
            throw GameError.invalidGameTime
        }
        isGameActive = true
    }
}

// 4. Betere shape management
struct ShapeManager {
    private let cache = NSCache<NSString, UIColor>()

    func getColor(for shape: ShapeType) -> Color {
        let key = NSString(string: "\(shape.rawValue)")

        if let cachedColor = cache.object(forKey: key) {
            return Color(cachedColor)
        }

        let color = UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )

        cache.setObject(color, forKey: key)
        return Color(color)
    }
}

class GameTimer: ObservableObject {
    @Published private(set) var remainingTime: Int
    @Published private(set) var isRunning: Bool = false
    
    private var timer: Timer?
    private let gameTime: Int
    private let displayRate: Int
    private var shapeDisplayTimer: Timer?
    private var onShapeDisplay: (() -> Void)?
    
    init(gameTime: Int, displayRate: Int) {
        self.gameTime = gameTime
        self.remainingTime = gameTime
        self.displayRate = displayRate
    }
    
    func start(onShapeDisplay: @escaping () -> Void) {
        guard !isRunning else { return }
        
        self.onShapeDisplay = onShapeDisplay
        isRunning = true
        remainingTime = gameTime
        
        // Start main game timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.stop()
            }
        }
        
        // Start shape display timer
        shapeDisplayTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(displayRate), repeats: true) { [weak self] _ in
            self?.onShapeDisplay?()
        }
        
        // Trigger first shape display immediately
        onShapeDisplay()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        shapeDisplayTimer?.invalidate()
        shapeDisplayTimer = nil
        isRunning = false
    }
    
    deinit {
        stop()
    }
}
