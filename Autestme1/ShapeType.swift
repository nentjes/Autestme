import SwiftUI

/// Definieert de verschillende vormen die in het spel kunnen voorkomen
enum ShapeType: Int, CaseIterable {
    /// Een enkele stip
    case dot
    /// Een horizontale lijn
    case line
    /// Een perfecte cirkel
    case circle
    /// Een ovaal
    case oval
    /// Een vierkant
    case square
    /// Een rechthoek
    case rectangle
    
    /// De weergavenaam van de vorm in het Nederlands
    var displayName: String {
        switch self {
        case .dot:
            return "Stip"
        case .line:
            return "Lijn"
        case .circle:
            return "Cirkel"
        case .oval:
            return "Ovaal"
        case .square:
            return "Vierkant"
        case .rectangle:
            return "Rechthoek"
        }
    }
    
    /// De standaardkleur voor deze vorm
    var color: Color {
        switch self {
        case .dot:
            return Color.red
        case .line:
            return Color.green
        case .circle:
            return Color.orange
        case .oval:
            return Color.yellow
        case .square:
            return Color.pink
        case .rectangle:
            return Color.blue
        }
    }

    /// Maakt een SwiftUI view voor deze vorm
    /// - Returns: Een view die de vorm weergeeft
    func shapeView() -> some View {
        switch self {
        case .dot:
            return AnyView(Circle())
        case .line:
            return AnyView(Rectangle().frame(height: 5))
        case .circle:
            return AnyView(Circle())
        case .oval:
            return AnyView(Ellipse())
        case .square:
            return AnyView(Rectangle())
        case .rectangle:
            return AnyView(Rectangle().aspectRatio(2, contentMode: .fit))
        }
    }
}

