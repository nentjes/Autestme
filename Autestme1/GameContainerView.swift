import SwiftUI
import Combine
import AVFoundation

struct GameContainerView: View {
    private let shapeDisplayRate: Int
    @StateObject private var gameTimer: GameTimer
    @ObservedObject private var gameLogic: GameLogic // <-- Correcte @ObservedObject
    @State private var shapeCounts: [ShapeType: Int]
    @State private var colorMode: ColorMode
    @State private var currentShape: ShapeType?
    @State private var currentLetter: Character?
    @State private var currentNumber: Int?
    @State private var goToEndScreen = false
    @State private var audioPlayer: AVAudioPlayer?

    @Binding var navigationPath: NavigationPath

    init(gameLogic: GameLogic, navigationPath: Binding<NavigationPath>) {
        self.gameLogic = gameLogic // <-- Correcte init
        self.shapeDisplayRate = gameLogic.displayRate
        self._gameTimer = StateObject(wrappedValue: GameTimer(gameTime: gameLogic.gameTime, displayRate: gameLogic.displayRate))
        self._shapeCounts = State(initialValue: Dictionary(uniqueKeysWithValues: ShapeType.allCases.map { ($0, 0) }))
        self._colorMode = State(initialValue: gameLogic.colorMode)
        self._navigationPath = navigationPath
    }

    var body: some View {
        VStack {
            Text("game_screen_title") // <-- Gelokaliseerd
                .font(.largeTitle)
                .padding()

            Text(String(format: NSLocalizedString("game_screen_time_left", comment: ""), "\(gameTimer.remainingTime)")) // <-- Gelokaliseerd
                .font(.title2)
                .padding()

            switch gameLogic.gameVersion {
            case .shapes:
                if let shape = currentShape {
                    shape.shapeView()
                        .foregroundColor(colorMode == .random ? .random() : shape.color)
                        .frame(width: 100, height: 100)
                }
            case .letters:
                if let letter = currentLetter {
                    Text(String(letter))
                        .font(.system(size: 100))
                        .foregroundColor(colorMode == .random ? .random() : gameLogic.letterColors[letter] ?? .blue)
                }
            case .numbers:
                if let number = currentNumber {
                    Text("\(number)")
                        .font(.system(size: 100))
                        .foregroundColor(colorMode == .random ? .random() : gameLogic.numberColors[number] ?? .orange)
                }
            }

            EmptyView()
                .onChange(of: goToEndScreen) { newValue in
                    if newValue {
                        navigationPath.append("endscreen")
                    }
                }
        }
        .onAppear {
            let firstShape = GameLogic.getRandomShape(shapes: gameLogic.shapeType)
            currentShape = firstShape
            shapeCounts[firstShape, default: 0] += 1
            firstShape.playSound(player: &audioPlayer)

            gameTimer.reset(gameTime: gameLogic.gameTime, displayRate: gameLogic.displayRate)

            gameTimer.start {
                switch gameLogic.gameVersion {
                case .shapes:
                    let newShape = GameLogic.getRandomShape(shapes: gameLogic.shapeType, excluding: currentShape)
                    currentShape = newShape
                    currentLetter = nil
                    currentNumber = nil
                    shapeCounts[newShape, default: 0] += 1
                    newShape.playSound(player: &audioPlayer)
                case .letters:
                    let allowedLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").prefix(gameLogic.numberOfItems)
                    let letter = allowedLetters.randomElement()!
                    currentLetter = letter
                    currentShape = nil
                    currentNumber = nil
                    gameLogic.letterCounts[letter, default: 0] += 1
                    playCommonClick()
                case .numbers:
                    let number = Int.random(in: 0..<gameLogic.numberOfItems)
                    currentNumber = number
                    currentShape = nil
                    currentLetter = nil
                    gameLogic.numberCounts[number, default: 0] += 1
                    playCommonClick()
                }
            }
        }
        .onChange(of: gameTimer.isRunning) { isRunning in
            if !isRunning {
                goToEndScreen = true
            }
        }
        .onDisappear {
            gameTimer.stop()
            currentShape = nil
            audioPlayer?.stop()
            audioPlayer = nil
        }
        .navigationDestination(for: String.self) { value in
            if value == "endscreen" {
                EndScreen(
                    shapeCounts: $shapeCounts,
                    dismissAction: { navigationPath.removeLast() },
                    restartAction: { navigationPath.removeLast() },
                    gameLogic: gameLogic, // <-- Correct (geen $)
                    navigationPath: $navigationPath
                )
            }
        }
    }
    
    func playCommonClick() {
        guard let url = Bundle.main.url(forResource: "click", withExtension: "mp3") else {
            print("Geluid niet gevonden")
            return
        }
        do {
            if audioPlayer?.isPlaying == true {
                audioPlayer?.stop()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.currentTime = 0
            audioPlayer?.play()
        } catch {
            print("Fout bij afspelen: \(error)")
        }
    }

    func playShapeSound(for shape: ShapeType) {
        let filename = shape.soundFileName
        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("Geluid voor \(shape.displayName) niet gevonden")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Fout bij afspelen geluid voor \(shape.displayName): \(error)")
        }
    }
}
