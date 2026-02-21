import SwiftUI
import WatchKit

enum WatchShapeType: Int, CaseIterable {
    case dot, line, circle, oval, square, rectangle

    var displayName: String {
        let key: String
        switch self {
        case .dot: key = "shape_dot"
        case .line: key = "shape_line"
        case .circle: key = "shape_circle"
        case .oval: key = "shape_oval"
        case .square: key = "shape_square"
        case .rectangle: key = "shape_rectangle"
        }
        return NSLocalizedString(key, comment: "Shape display name")
    }

    var color: Color {
        switch self {
        case .dot: return .red
        case .line: return .green
        case .circle: return .orange
        case .oval: return .yellow
        case .square: return .pink
        case .rectangle: return .blue
        }
    }

    func shapeView() -> some View {
        switch self {
        case .dot: return AnyView(Circle().frame(width: 12, height: 12))
        case .line: return AnyView(Rectangle().frame(height: 4))
        case .circle: return AnyView(Circle().frame(width: 50, height: 50))
        case .oval: return AnyView(Ellipse().frame(width: 60, height: 36))
        case .square: return AnyView(Rectangle().frame(width: 50, height: 50))
        case .rectangle: return AnyView(Rectangle().frame(width: 70, height: 36))
        }
    }

    func playHaptic() {
        WKInterfaceDevice.current().play(.click)
    }
}
