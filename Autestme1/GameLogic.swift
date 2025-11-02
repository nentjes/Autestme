import SwiftUI
import Combine
import Foundation

enum ColorMode: String, CaseIterable, Identifiable {
    case fixed
    case random

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fixed:
            return "Vaste kleur per vorm"
        case .random:
            return "Willekeurige kleur"
        }
    }
}

extension Color {
    static func random() -> Color {
        let red = Double.random(in: 0...1)
        let green = Double.random(in: 0...1)
        let blue = Double.random(in: 0...1)
        return Color(red: red, green: green, blue: blue)
    }
}

enum GameVersion {
    case shapes
    case letters
    case numbers
}

class GameLogic: ObservableObject, Equatable, Hashable {
    var gameID: UUID
    var startScreenID: UUID
    var gameVersion: GameVersion
    var gameTime: Int
    var colorMode: ColorMode
    var displayRate: Int
    
    var shapeColors: [ShapeType: Color] = [:]
    var letterColors: [Character: Color] = [:]
    var numberColors: [Int: Color] = [:]

    var shapeType: [ShapeType]
    
    var shapeCounts: [ShapeType: Int] = [:]
    var letterCounts: [Character: Int] = [:]
    var numberCounts: [Int: Int] = [:]
    
    var shapeSequence: [ShapeType] = []
    var letterSequence: [Character] = []
    var numberSequence: [Int] = []
    
    var remainingTime: Int
    var player: String
    var score: Int
    
    var numberOfItems: Int


    init(gameTime: Int, gameVersion: GameVersion, colorMode: ColorMode, displayRate: Int, player: String, numberOfShapes: Int) {
        self.gameID = UUID()
        self.startScreenID = UUID()
        self.gameTime = gameTime
        self.gameVersion = gameVersion
        self.colorMode = colorMode
        self.displayRate = displayRate
        self.remainingTime = gameTime
        self.player = player
        self.numberOfItems = numberOfShapes

        self.shapeType = GameLogic.generateShapes(numberOfShapes: numberOfShapes) // <-- Gebruikt de GECORRIGEERDE functie
        self.score = 0

        setupShapeColors()
        setupLetterAndNumberColors()
        resetCounts()
    }

    
    // HIER IS DE HIGHSCORE RESET FIX
    func reset() {
        gameTime = 10
        shapeCounts = [:]
        letterCounts = [:]
        numberCounts = [:]
        shapeSequence = []
        letterSequence = []
        numberSequence = []
        remainingTime = gameTime
        // player = "Player1" // <-- DEZE REGEL IS VERWIJDERD
        score = 0
    }
    
    private func setupShapeColors() {
        let allColors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]

        for shape in ShapeType.allCases {
            if let randomColor = allColors.randomElement() {
                shapeColors[shape] = randomColor
            }
        }
    }

    private func setupLetterAndNumberColors() {
        let allColors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        
        let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").prefix(numberOfItems)
        for letter in letters {
            letterColors[letter] = allColors.randomElement() ?? .gray
        }

        for number in 0..<numberOfItems {
            numberColors[number] = allColors.randomElement() ?? .gray
        }
    }

    
    private func resetCounts() {
        switch gameVersion {
        case .shapes:
            for shape in ShapeType.allCases {
                shapeCounts[shape] = 0
            }
        case .letters:
            let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").prefix(numberOfItems)
            for letter in letters {
                letterCounts[letter] = 0
            }

        case .numbers:
            for number in 0..<numberOfItems {
                numberCounts[number] = 0
            }
        }
    }
    
    static func == (lhs: GameLogic, rhs: GameLogic) -> Bool {
        return lhs.gameID == rhs.gameID
        // ... (de rest van je == implementatie)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(gameID)
        // ... (de rest van je hash implementatie)
    }

    static func getRandomShape(shapes: [ShapeType], excluding lastShape: ShapeType? = nil, lastShapes: [ShapeType] = []) -> ShapeType {
        if shapes.count == 1 {
            return shapes[0]
        }
        
        var availableShapes = shapes.filter { shape in
            !lastShapes.contains(shape)
        }
        
        if availableShapes.isEmpty {
            availableShapes = shapes
        }
        
        if let lastShape = lastShape {
            availableShapes = availableShapes.filter { $0 != lastShape }
        }
        
        if availableShapes.isEmpty {
            availableShapes = shapes
        }
        
        let randomIndex = Int.random(in: 0..<availableShapes.count)
        return availableShapes[randomIndex]
    }

    // HIER IS DE GENERATESHAPES FIX
    static func generateShapes(numberOfShapes: Int) -> [ShapeType] {
        // Zorgt voor UNIEKE vormen
        return Array(ShapeType.allCases.shuffled().prefix(numberOfShapes))
    }
}
extension GameLogic {
    static func getHighScore(for player: String, gameVersion: GameVersion) -> Int {
        let key = "highscore_\(player)_\(gameVersion)"
        return UserDefaults.standard.integer(forKey: key)
    }

    static func setHighScore(_ score: Int, for player: String, gameVersion: GameVersion) {
        let key = "highscore_\(player)_\(gameVersion)"
        UserDefaults.standard.set(score, forKey: key)
    }
}
