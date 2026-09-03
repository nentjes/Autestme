import SwiftUI
import Combine

// MARK: - GameContainerView — the Toy Mint play surface.
//
// During play we show only what the player needs to concentrate: the time
// remaining, a way to mute, and the current item. Game, timer, sound and
// navigation logic are unchanged from before — this file is a visual pass.

struct GameContainerView: View {
    private let shapeDisplayRate: Int
    @StateObject private var gameTimer: GameTimer
    @ObservedObject private var gameLogic: GameLogic
    @State private var shapeCounts: [ShapeType: Int]
    @State private var colorMode: ColorMode
    @State private var currentShape: ShapeType?
    @State private var currentLetter: Character?
    @State private var currentNumber: Int?
    @State private var goToEndScreen = false
    @AppStorage("isSoundEnabled") private var isSoundEnabled: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding var navigationPath: NavigationPath

    init(gameLogic: GameLogic, navigationPath: Binding<NavigationPath>) {
        self.gameLogic = gameLogic
        self.shapeDisplayRate = gameLogic.displayRate
        self._gameTimer = StateObject(
            wrappedValue: GameTimer(
                gameTime: gameLogic.gameTime,
                displayRate: gameLogic.displayRate
            )
        )
        self._shapeCounts = State(
            initialValue: Dictionary(uniqueKeysWithValues: ShapeType.allCases.map { ($0, 0) })
        )
        self._colorMode = State(initialValue: gameLogic.colorMode)
        self._navigationPath = navigationPath
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.mintPetrolDeep
                .ignoresSafeArea()

            VStack(spacing: 0) {
                controlBar
                    .padding(.horizontal, ToyMint.Spacing.l)
                    .padding(.top, ToyMint.Spacing.s)

                Spacer(minLength: 0)

                stage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer(minLength: 0)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.mintPetrolDeep, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: startGameLoop)
        .onChange(of: gameTimer.isRunning) { isRunning in
            if !isRunning { goToEndScreen = true }
        }
        .onChange(of: goToEndScreen) { shouldNavigate in
            if shouldNavigate { navigationPath.append("endscreen") }
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
                    gameLogic: gameLogic,
                    navigationPath: $navigationPath
                )
            }
        }
    }

    // MARK: - Control bar (compact time + mute)

    private var controlBar: some View {
        HStack(spacing: ToyMint.Spacing.m) {
            timeReadout
            Spacer(minLength: 0)
            soundToggle
        }
    }

    private var timeReadout: some View {
        HStack(spacing: ToyMint.Spacing.s) {
            Image(systemName: "hourglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.mintCream.opacity(0.75))
                .accessibilityHidden(true)
            Text("\(gameTimer.remainingTime)")
                .font(ToyMintFont.counter)
                .foregroundColor(.mintYellow)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.vertical, ToyMint.Spacing.xs)
        .padding(.horizontal, ToyMint.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: ToyMint.Radius.s, style: .continuous)
                .fill(Color.mintPetrol)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToyMint.Radius.s, style: .continuous)
                .strokeBorder(Color.mintChrome.opacity(0.35), lineWidth: ToyMint.Stroke.hair)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("mint_time_label"))
        .accessibilityValue(Text(String(format: NSLocalizedString(
            "mint_seconds_verbose", comment: "%d seconds"
        ), gameTimer.remainingTime)))
    }

    private var soundToggle: some View {
        Button {
            SoundManager.shared.playClick()
            SoundManager.shared.isSoundEnabled.toggle()
            isSoundEnabled = SoundManager.shared.isSoundEnabled
        } label: {
            Image(systemName: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isSoundEnabled ? .mintCream : .mintChrome)
                .frame(width: ToyMint.Layout.touchTarget,
                       height: ToyMint.Layout.touchTarget)
                .background(
                    Circle()
                        .fill(Color.mintPetrol)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.mintChrome.opacity(0.35),
                                      lineWidth: ToyMint.Stroke.hair)
                )
        }
        .accessibilityLabel(Text(isSoundEnabled
            ? "mint_sound_on_accessibility"
            : "mint_sound_off_accessibility"))
        .accessibilityHint(Text("mint_sound_toggle_hint"))
        .accessibilityAddTraits(isSoundEnabled ? [.isSelected] : [])
    }

    // MARK: - Stage (single centred play object)

    private var stage: some View {
        Group {
            switch gameLogic.gameVersion {
            case .shapes:  shapeStage
            case .letters: letterStage
            case .numbers: numberStage
            }
        }
        .padding(.horizontal, ToyMint.Spacing.xl)
    }

    // Stable identity per emission — lets the transition fire once per new item.
    private var shapeToken: String {
        currentShape.map { "s\($0.rawValue)-\(shapeCounts[$0, default: 0])" } ?? "s-none"
    }
    private var letterToken: String {
        currentLetter.map { "l\($0)-\(gameLogic.letterCounts[$0, default: 0])" } ?? "l-none"
    }
    private var numberToken: String {
        currentNumber.map { "n\($0)-\(gameLogic.numberCounts[$0, default: 0])" } ?? "n-none"
    }

    private var itemTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.94))
    }

    private var itemAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: 0.16)
    }

    @ViewBuilder
    private var shapeStage: some View {
        if let shape = currentShape {
            shape.shapeView()
                .foregroundColor(colorMode == .random
                    ? ToyMintPalette.randomPlayful()
                    : ToyMintPalette.color(for: shape))
                .frame(width: 180, height: 180)
                .id(shapeToken)
                .transition(itemTransition)
                .animation(itemAnimation, value: shapeToken)
                .accessibilityLabel(shape.displayName)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    @ViewBuilder
    private var letterStage: some View {
        if let letter = currentLetter {
            Text(String(letter))
                .font(.system(size: 220, weight: .bold, design: .serif))
                .foregroundColor(colorMode == .random
                    ? ToyMintPalette.randomPlayful()
                    : ToyMintPalette.color(for: letter))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .id(letterToken)
                .transition(itemTransition)
                .animation(itemAnimation, value: letterToken)
                .accessibilityLabel(Text(String(format: NSLocalizedString(
                    "mint_letter_accessibility", comment: "Letter %@"
                ), String(letter))))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    @ViewBuilder
    private var numberStage: some View {
        if let number = currentNumber {
            Text("\(number)")
                .font(.system(size: 220, weight: .bold, design: .monospaced))
                .foregroundColor(colorMode == .random
                    ? ToyMintPalette.randomPlayful()
                    : ToyMintPalette.color(for: number))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .id(numberToken)
                .transition(itemTransition)
                .animation(itemAnimation, value: numberToken)
                .accessibilityLabel(Text(String(format: NSLocalizedString(
                    "mint_number_accessibility", comment: "Number %d"
                ), number)))
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    // MARK: - Game loop (unchanged behaviour)

    private func startGameLoop() {
        let firstShape = GameLogic.getRandomShape(shapes: gameLogic.shapeType)
        currentShape = firstShape
        shapeCounts[firstShape, default: 0] += 1
        SoundManager.shared.playShape(firstShape)

        gameTimer.reset(gameTime: gameLogic.gameTime, displayRate: gameLogic.displayRate)

        gameTimer.start {
            switch gameLogic.gameVersion {
            case .shapes:
                let newShape = GameLogic.getRandomShape(
                    shapes: gameLogic.shapeType,
                    excluding: currentShape
                )
                currentShape = newShape
                currentLetter = nil
                currentNumber = nil
                shapeCounts[newShape, default: 0] += 1
                SoundManager.shared.playShape(newShape)
            case .letters:
                let allowedLetters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                    .prefix(gameLogic.numberOfItems)
                let letter = allowedLetters.randomElement()!
                currentLetter = letter
                currentShape = nil
                currentNumber = nil
                gameLogic.letterCounts[letter, default: 0] += 1
                SoundManager.shared.playLetter()
            case .numbers:
                let number = Int.random(in: 0..<gameLogic.numberOfItems)
                currentNumber = number
                currentShape = nil
                currentLetter = nil
                gameLogic.numberCounts[number, default: 0] += 1
                SoundManager.shared.playNumber()
            }
        }
    }
}
