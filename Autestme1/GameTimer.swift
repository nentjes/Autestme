import Foundation
import SwiftUI
import Combine

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
