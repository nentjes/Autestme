import SwiftUI
import Combine

enum WatchColorMode: String, CaseIterable, Identifiable {
    case fixed
    case random

    var id: String { rawValue }
}

extension Color {
    static func watchRandom() -> Color {
        Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

class WatchGameLogic: ObservableObject, Hashable {
    static func == (lhs: WatchGameLogic, rhs: WatchGameLogic) -> Bool {
        lhs.gameID == rhs.gameID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(gameID)
    }
    let gameID = UUID()
    let gameTime: Int
    let colorMode: WatchColorMode
    let displayRate: Int
    let numberOfShapes: Int
    let shapeTypes: [WatchShapeType]

    var shapeCounts: [WatchShapeType: Int] = [:]
    var shapeSequence: [WatchShapeType] = []

    @Published var score: Int = 0

    init(gameTime: Int, colorMode: WatchColorMode, displayRate: Int, numberOfShapes: Int) {
        self.gameTime = gameTime
        self.colorMode = colorMode
        self.displayRate = displayRate
        self.numberOfShapes = numberOfShapes
        self.shapeTypes = Array(WatchShapeType.allCases.shuffled().prefix(numberOfShapes))

        for shape in WatchShapeType.allCases {
            shapeCounts[shape] = 0
        }
    }

    static func getRandomShape(from shapes: [WatchShapeType], excluding last: WatchShapeType? = nil) -> WatchShapeType {
        if shapes.count == 1 { return shapes[0] }

        var available = shapes
        if let last = last {
            available = shapes.filter { $0 != last }
        }
        if available.isEmpty { available = shapes }

        return available[Int.random(in: 0..<available.count)]
    }

    // MARK: - Highscore

    static func getHighScore() -> Int {
        UserDefaults.standard.integer(forKey: "watch_highscore_shapes")
    }

    static func setHighScore(_ score: Int) {
        UserDefaults.standard.set(score, forKey: "watch_highscore_shapes")
    }
}
