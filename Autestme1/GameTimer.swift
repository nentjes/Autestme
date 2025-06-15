import Foundation
import SwiftUI

class GameTimer: ObservableObject {
    @Published private(set) var remainingTime: Int
    @Published private(set) var isRunning: Bool = false

    private var timer: Timer?
    private var shapeTimer: Timer?

    private let gameTime: Int
    private let displayRate: Int

    init(gameTime: Int, displayRate: Int) {
        self.remainingTime = gameTime
        self.gameTime = gameTime
        self.displayRate = displayRate
    }

    func start(onShapeDisplay: @escaping () -> Void) {
        isRunning = true
        remainingTime = gameTime

        // aftellen
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.remainingTime -= 1
            if self.remainingTime <= 0 {
                self.stop()
            }
        }

        // vormen laten zien
        shapeTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / Double(displayRate), repeats: true) { _ in
            if self.remainingTime > 0 {
                onShapeDisplay()
            }
        }
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        shapeTimer?.invalidate()
        timer = nil
        shapeTimer = nil
    }

    func reset(gameTime: Int, displayRate: Int) {
        stop()
        self.remainingTime = gameTime
        self.timer = nil
        self.shapeTimer = nil
        self.isRunning = false
    }
}
