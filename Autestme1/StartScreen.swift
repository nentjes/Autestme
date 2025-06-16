import SwiftUI

struct StartScreen: View {
    @Binding var navigationPath: NavigationPath

    @State private var gameDuration: Double = 10
    @State private var numberOfShapes: Double = 3
    @State private var shapeDisplayRate: Double = 1
    @State private var selectedColorMode: ColorMode = .fixed
    @State private var showInfoAlert = false
    @State private var selectedGameVersion: GameVersion = .shapes


    // computed property to determine the range for the slider based on the selected game
    var labelForType: String {
        switch selectedGameVersion {
        case .shapes: return "figuren"
        case .numbers: return "cijfers"
        case .letters: return "letters"
        }
    }

    var rangeForType: ClosedRange<Double> {
        switch selectedGameVersion {
        case .shapes: return 1...Double(ShapeType.allCases.count)
        case .numbers: return 1...10
        case .letters: return 1...26
        }
    }

    private func createGameLogic() -> GameLogic {
        return GameLogic(
            gameTime: Int(gameDuration),
            gameVersion: selectedGameVersion,
            colorMode: selectedColorMode,
            displayRate: Int(shapeDisplayRate),
            player: "Player 1",
            numberOfShapes: Int(numberOfShapes)
        )
    }

    var body: some View {
        VStack {
            HStack {
                Text("Autestme")
                    .font(.largeTitle)
                    .bold()
                
                Button(action: {
                    showInfoAlert = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
                .alert("Speluitleg", isPresented: $showInfoAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("""
                    Welkom bij Autestme!

                    In dit spel worden verschillende vormen, letters of cijfers getoond. 
                    Je taak is om te onthouden hoe vaak je elk item hebt gezien.

                    Speltypes:
                    • Vormen – cirkels, vierkanten, lijnen enz.
                    • Letters – willekeurige hoofdletters (A t/m Z)
                    • Cijfers – willekeurige cijfers (0 t/m 9)

                    Instellingen:
                    • Spelduur – hoe lang het spel duurt
                    • Tempo – hoe snel de items elkaar opvolgen
                    • Aantal figuren – bij vormen: hoeveel verschillende figuren, bij letters/cijfers: uit hoeveel verschillende opties gekozen wordt
                    
                    • Kleurmodus – vaste kleuren per item of willekeurige kleuren.

                    Succes!

                    """)
                }
            }
            .padding()

            VStack {
                Text("Spelduur: \(Int(gameDuration)) seconden")
                Slider(value: $gameDuration, in: 5...30)
            }
            .padding()

            VStack {
                Text("Tempo: \(Int(shapeDisplayRate))")
                Slider(value: $shapeDisplayRate, in: 1...10)
            }
            .padding()

            VStack {
                Text("Kleurmodus")
                    .padding()
                Picker("Kleurmodus", selection: $selectedColorMode) {
                    Text("Vast").tag(ColorMode.fixed)
                    Text("Willekeurig").tag(ColorMode.random)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()

            VStack {
                Text("Speltype")
                    .padding(.top)
                Picker("Speltype", selection: $selectedGameVersion) {
                    Text("Vormen").tag(GameVersion.shapes)
                    Text("Letters").tag(GameVersion.letters)
                    Text("Cijfers").tag(GameVersion.numbers)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()

            
            VStack {
                Text("Aantal verschillende \(labelForType): \(Int(numberOfShapes))")
                Slider(value: $numberOfShapes, in: rangeForType, step: 1)
            }
            .padding()

            
            Button(action: {
                let logic = createGameLogic()
                logic.displayRate = Int(shapeDisplayRate)
                navigationPath.append(logic)
            }) {
                Text("Start het spel")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationDestination(for: GameLogic.self) { logic in
            GameContainerView(gameLogic: logic, navigationPath: $navigationPath)
        }
    }
}

