import SwiftUI

struct StartScreen: View {
    @Binding var navigationPath: NavigationPath

    @State private var gameDuration: Double = 10
    @State private var numberOfShapes: Double = 3
    @State private var shapeDisplayRate: Double = 1
    @State private var selectedColorMode: ColorMode = .fixed
    @State private var showInfoAlert = false

    private func createGameLogic() -> GameLogic {
        return GameLogic(
            gameTime: Int(gameDuration),
            gameVersion: .shapes,
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

                    In dit spel worden verschillende vormen getoond. Je taak is om te onthouden hoeveel keer je elke vorm hebt gezien.

                    Instellingen:
                    • Spelduur: Hoe lang het spel duurt
                    • Aantal figuren: Hoeveel verschillende vormen er zijn
                    • Tempo: Hoe snel de vormen worden getoond
                    • Kleurmodus: Vast of willekeurige kleuren

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
                Text("Aantal verschillende figuren: \(Int(numberOfShapes))")
                Slider(value: $numberOfShapes, in: 1...Double(ShapeType.allCases.count))
            }
            .padding()

            VStack {
                Text("Tempo figuren: \(Int(shapeDisplayRate))")
                Slider(value: $shapeDisplayRate, in: 1...10)
            }
            .padding()

            VStack {
                Text("Kies een kleurmodus")
                    .font(.title2)
                    .padding()
                Picker("Kleurmodus", selection: $selectedColorMode) {
                    Text("Vast").tag(ColorMode.fixed)
                    Text("Willekeurig").tag(ColorMode.random)
                }
                .pickerStyle(SegmentedPickerStyle())
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

