import SwiftUI
import Combine

struct GameContainerView: View {
    private let shapeDisplayRate: Int
    @StateObject private var gameTimer: GameTimer
    @ObservedObject private var gameLogic: GameLogic // <-- Correct @ObservedObject
    @State private var shapeCounts: [ShapeType: Int]
    @State private var colorMode: ColorMode
    @State private var currentShape: ShapeType?
    @State private var currentLetter: Character?
    @State private var currentNumber: Int?
    @State private var goToEndScreen = false
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true

    @Binding var navigationPath: NavigationPath

    init(gameLogic: GameLogic, navigationPath: Binding<NavigationPath>) {
        self.gameLogic = gameLogic // <-- Correct init
        self.shapeDisplayRate = gameLogic.displayRate
        self._gameTimer = StateObject(wrappedValue: GameTimer(gameTime: gameLogic.gameTime, displayRate: gameLogic.displayRate))
        self._shapeCounts = State(initialValue: Dictionary(uniqueKeysWithValues: ShapeType.allCases.map { ($0, 0) }))
        self._colorMode = State(initialValue: gameLogic.colorMode)
        self._navigationPath = navigationPath
    }

    var body: some View {
        VStack {
            Text("game_screen_title") // <-- Localized
                .font(.largeTitle)
                .padding()

            HStack {
                Text(String(format: NSLocalizedString("game_screen_time_left", comment: ""), "\(gameTimer.remainingTime)")) // <-- Localized
                    .font(.title2)
                    .padding()
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue("\(gameTimer.remainingTime) seconds")
                Spacer()
                Button {
                    SoundManager.shared.isSoundEnabled.toggle()
                    isSoundEnabled = SoundManager.shared.isSoundEnabled
                } label: {
                    Image(systemName: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .accessibilityLabel(isSoundEnabled ? "Geluid uit" : "Geluid aan")
                .padding(.trailing)
            }

            switch gameLogic.gameVersion {
            case .shapes:
                if let shape = currentShape {
                    shape.shapeView()
                        .foregroundColor(colorMode == .random ? .random() : shape.color)
                        .frame(width: 100, height: 100)
                        .accessibilityLabel(shape.displayName)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            case .letters:
                if let letter = currentLetter {
                    Text(String(letter))
                        .font(.system(size: 100))
                        .foregroundColor(colorMode == .random ? .random() : gameLogic.letterColors[letter] ?? .blue)
                        .accessibilityLabel("Letter \(letter)")
                        .accessibilityAddTraits(.updatesFrequently)
                }
            case .numbers:
                if let number = currentNumber {
                    Text("\(number)")
                        .font(.system(size: 100))
                        .foregroundColor(colorMode == .random ? .random() : gameLogic.numberColors[number] ?? .orange)
                        .accessibilityLabel("Number \(number)")
                        .accessibilityAddTraits(.updatesFrequently)
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
            SoundManager.shared.playNote(firstShape.midiNote)

            gameTimer.reset(gameTime: gameLogic.gameTime, displayRate: gameLogic.displayRate)

            gameTimer.start {
                switch gameLogic.gameVersion {
                case .shapes:
                    let newShape = GameLogic.getRandomShape(shapes: gameLogic.shapeType, excluding: currentShape)
                    currentShape = newShape
                    currentLetter = nil
                    currentNumber = nil
                    shapeCounts[newShape, default: 0] += 1
                    SoundManager.shared.playNote(newShape.midiNote)
                case .letters:
                    let allowedLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").prefix(gameLogic.numberOfItems)
                    let letter = allowedLetters.randomElement()!
                    currentLetter = letter
                    currentShape = nil
                    currentNumber = nil
                    gameLogic.letterCounts[letter, default: 0] += 1
                    let letterIndex = UInt8(letter.asciiValue.map { Int($0) - Int(Character("A").asciiValue!) } ?? 0)
                    SoundManager.shared.playNote(48 + letterIndex)
                case .numbers:
                    let number = Int.random(in: 0..<gameLogic.numberOfItems)
                    currentNumber = number
                    currentShape = nil
                    currentLetter = nil
                    gameLogic.numberCounts[number, default: 0] += 1
                    // Majeur toonladder: C D E F G A B C D E F
                    let scale: [UInt8] = [60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77]
                    SoundManager.shared.playNote(scale[min(number, scale.count - 1)])
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
        }
        .navigationDestination(for: String.self) { value in
            if value == "endscreen" {
                EndScreen(
                    shapeCounts: $shapeCounts,
                    dismissAction: { navigationPath.removeLast() },
                    restartAction: { navigationPath.removeLast() },
                    gameLogic: gameLogic, // <-- Correct (no $)
                    navigationPath: $navigationPath
                )
            }
        }
    }
}
