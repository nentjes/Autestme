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
        self.numberOfItems = numberOfShapes  // <--- voeg dit toe

        self.shapeType = GameLogic.generateShapes(numberOfShapes: numberOfShapes)
        self.score = 0

        setupShapeColors()
        setupLetterAndNumberColors()
        resetCounts()
    }

    
    func reset() {
        gameTime = 10
        shapeCounts = [:]
        letterCounts = [:]
        numberCounts = [:]
        shapeSequence = []
        letterSequence = []
        numberSequence = []
        remainingTime = gameTime
        player = "Player1"
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
        return lhs.gameID == rhs.gameID &&
               lhs.startScreenID == rhs.startScreenID &&
               lhs.gameTime == rhs.gameTime &&
               lhs.gameVersion == rhs.gameVersion &&
               lhs.colorMode == rhs.colorMode &&
               lhs.displayRate == rhs.displayRate &&
               lhs.remainingTime == rhs.remainingTime &&
               lhs.player == rhs.player &&
               lhs.shapeType == rhs.shapeType &&
               lhs.score == rhs.score
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(gameID)
        hasher.combine(startScreenID)
        hasher.combine(gameTime)
        hasher.combine(gameVersion)
        hasher.combine(colorMode)
        hasher.combine(displayRate)
        hasher.combine(remainingTime)
        hasher.combine(player)
        hasher.combine(shapeType)
        hasher.combine(score)
    }

    /// Genereert een willekeurige vorm die niet dezelfde is als de laatste vorm
    /// - Parameters:
    ///   - shapes: De beschikbare vormen
    ///   - lastShape: De laatst getoonde vorm
    ///   - lastShapes: Een array van de laatste getoonde vormen om te voorkomen dat vormen te vaak herhaald worden
    /// - Returns: Een willekeurige vorm die niet in de laatste vormen voorkomt
    static func getRandomShape(shapes: [ShapeType], excluding lastShape: ShapeType? = nil, lastShapes: [ShapeType] = []) -> ShapeType {
        // Als er maar één vorm beschikbaar is, geef die terug
        if shapes.count == 1 {
            return shapes[0]
        }
        
        // Filter de vormen die niet in de laatste vormen voorkomen
        var availableShapes = shapes.filter { shape in
            !lastShapes.contains(shape)
        }
        
        // Als er geen vormen meer over zijn, reset de beschikbare vormen
        if availableShapes.isEmpty {
            availableShapes = shapes
        }
        
        // Verwijder de laatste vorm als die bestaat
        if let lastShape = lastShape {
            availableShapes = availableShapes.filter { $0 != lastShape }
        }
        
        // Als er nog steeds geen vormen beschikbaar zijn, gebruik alle vormen
        if availableShapes.isEmpty {
            availableShapes = shapes
        }
        
        // Kies een willekeurige vorm
        let randomIndex = Int.random(in: 0..<availableShapes.count)
        return availableShapes[randomIndex]
    }

    static func generateShapes(numberOfShapes: Int) -> [ShapeType] {
        var generatedShapes: [ShapeType] = []
        for _ in 0..<numberOfShapes {
            if let randomShape = ShapeType.allCases.randomElement() {
                generatedShapes.append(randomShape)
            }
        }
        return generatedShapes
    }
}


