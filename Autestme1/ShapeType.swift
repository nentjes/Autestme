import SwiftUI
import AVFoundation

enum ShapeType: Int, CaseIterable {
    case dot, line, circle, oval, square, rectangle

    var displayName: String {
        switch self {
        case .dot: return "Stip"
        case .line: return "Lijn"
        case .circle: return "Cirkel"
        case .oval: return "Ovaal"
        case .square: return "Vierkant"
        case .rectangle: return "Rechthoek"
        }
    }

    var color: Color {
        switch self {
        case .dot: return Color.red
        case .line: return Color.green
        case .circle: return Color.orange
        case .oval: return Color.yellow
        case .square: return Color.pink
        case .rectangle: return Color.blue
        }
    }

    var soundFileName: String {
        switch self {
        case .dot: return "dot"
        case .line: return "line"
        case .circle: return "circle"
        case .oval: return "oval"
        case .square: return "square"
        case .rectangle: return "rectangle"
        }
    }

    
    func shapeView() -> some View {
        switch self {
        case .dot: return AnyView(Circle().frame(width: 20, height: 20))
        case .line: return AnyView(Rectangle().frame(height: 5))
        case .circle: return AnyView(Circle().frame(width: 80, height: 80))
        case .oval: return AnyView(Ellipse().frame(width: 100, height: 60))
        case .square: return AnyView(Rectangle().frame(width: 80, height: 80))
        case .rectangle: return AnyView(Rectangle().frame(width: 120, height: 60))
        }
    }

    func playSound(player: inout AVAudioPlayer?) {
        let soundName = "\(self)" // bijv. "dot", "circle", etc.
        
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("❌ Geluid '\(soundName).mp3' niet gevonden")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            print("✅ Geluid '\(soundName).mp3' afgespeeld")
        } catch {
            print("❌ Fout bij afspelen '\(soundName).mp3': \(error.localizedDescription)")
        }
    }

}

