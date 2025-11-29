import SwiftUI
import AVFoundation
import Foundation // <-- Important for localization

enum ShapeType: Int, CaseIterable {
    case dot, line, circle, oval, square, rectangle

    // CORRECTIE: We gebruiken NSLocalizedString om de korte namen op te halen uit de .strings files
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

    // HERE IS THE CORRECT PLAY-SOUND (which stops if already playing)
    func playSound(player: inout AVAudioPlayer?) {
        let soundName = "\(self)"
        
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("❌ Sound '\(soundName).mp3' not found")
            return
        }

        do {
            if player?.isPlaying == true {
                player?.stop()
            }
            
            player = try AVAudioPlayer(contentsOf: url)
            player?.currentTime = 0
            player?.prepareToPlay()
            player?.play()
            print("✅ Sound '\(soundName).mp3' played")
        } catch {
            print("❌ Error playing '\(soundName).mp3': \(error.localizedDescription)")
        }
    }
}
