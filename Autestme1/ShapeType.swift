import SwiftUI

enum ShapeType: Int, CaseIterable {
    case dot, line, circle, oval, square, rectangle
    
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

