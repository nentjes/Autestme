import SwiftUI
import Combine
import AVFoundation


struct ShapeDisplayView: View {
    let shapes: [ShapeType]
    let displayRate: Int
    let colorMode: ColorMode
    let gameVersion: GameVersion
    @Binding var shapeCounts: [ShapeType: Int]
    
    @State private var currentShape: ShapeType? = nil
    @State private var timerCancellable: AnyCancellable? = nil
    @State private var lastShape: ShapeType? = nil

    func playClickSound() {
        guard let url = Bundle.main.url(forResource: "click", withExtension: "mp3") else {
            print("click.mp3 niet gevonden")
            return
        }

        var player: AVAudioPlayer?
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Fout bij afspelen click.mp3: \(error)")
        }
    }

    var body: some View {
        VStack {
            if let shape = currentShape {
                shape.shapeView()
                    .foregroundColor(colorMode == .random ? .random() : shape.color)
                    .frame(width: 100, height: 100)
            } else {
                Text("Klaar om te starten")
            }
        }
        .onAppear {
            timerCancellable = Timer.publish(every: TimeInterval(displayRate), on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    let currentShape = GameLogic.getRandomShape(shapes: shapes, excluding: lastShape)
                        lastShape = currentShape
                    self.currentShape = currentShape
                    shapeCounts[currentShape, default: 0] += 1

                    if gameVersion == .letters || gameVersion == .numbers {
                        playClickSound()
                    }

                    }
                }
        
        .onDisappear {
            timerCancellable?.cancel()
        }
    }
}

