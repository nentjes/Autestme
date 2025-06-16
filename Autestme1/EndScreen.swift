
import SwiftUI

struct EndScreen: View {
    @Binding var shapeCounts: [ShapeType: Int]
    let dismissAction: () -> Void
    let restartAction: () -> Void
    @Binding var gameLogic: GameLogic
    @Binding var navigationPath: NavigationPath

    @State private var enteredShapes: [ShapeType: Int] = [:]
    @State private var enteredLetters: [Character: Int] = [:]
    @State private var enteredNumbers: [Int: Int] = [:]
    @State private var isShowingResults = false
    @State private var textInputs: [AnyHashable: String] = [:]


    private var totalCorrect: Int {
        switch gameLogic.gameVersion {
        case .shapes:
            return shapeCounts.reduce(0) { acc, pair in
                let entered = enteredShapes[pair.key] ?? 0
                return acc + (entered == pair.value ? 1 : 0)
            }
        case .letters:
            return gameLogic.letterCounts.filter { $0.value > 0 }.reduce(0) { acc, pair in
                let entered = enteredLetters[pair.key] ?? 0
                return acc + (entered == pair.value ? 1 : 0)
            }
        case .numbers:
            return gameLogic.numberCounts.filter { $0.value > 0 }.reduce(0) { acc, pair in
                let entered = enteredNumbers[pair.key] ?? 0
                return acc + (entered == pair.value ? 1 : 0)
            }
        }
    }

    var body: some View {
        VStack {
            Text("Eindscherm")
                .font(.largeTitle)
                .padding()

            if isShowingResults {
                Text("Resultaten:")
                    .font(.title)
                    .padding()

                switch gameLogic.gameVersion {
                case .shapes:
                    resultList(data: shapeCounts.map { ($0.key.displayName, enteredShapes[$0.key] ?? 0, $0.value) })
                case .letters:
                    resultList(data: gameLogic.letterCounts.filter { $0.value > 0 }
                        .map { (String($0.key), enteredLetters[$0.key] ?? 0, $0.value) })
                case .numbers:
                    resultList(data: gameLogic.numberCounts.filter { $0.value > 0 }
                        .map { (String($0.key), enteredNumbers[$0.key] ?? 0, $0.value) })
                }

                Text("Score: \(totalCorrect)")
                    .font(.title2)
                    .padding()

                Button("Terug naar start") {
                    gameLogic.reset()
                    navigationPath.removeLast(navigationPath.count)
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("Voer in hoeveel je hebt gezien:")
                    .font(.title2)
                    .padding()

                switch gameLogic.gameVersion {
                case .shapes:
                    entryList(
                        items: shapeCounts.map { $0.key },
                        getValue: { enteredShapes[$0] ?? 0 },
                        setValue: { enteredShapes[$0] = $1 },
                        label: { $0.displayName }
                    )
                case .letters:
                    entryList(
                        items: gameLogic.letterCounts.filter { $0.value > 0 }.map { $0.key }.sorted(),
                        getValue: { enteredLetters[$0] ?? 0 },
                        setValue: { enteredLetters[$0] = $1 },
                        label: { String($0) }
                    )
                case .numbers:
                    entryList(
                        items: gameLogic.numberCounts.filter { $0.value > 0 }.map { $0.key }.sorted(),
                        getValue: { enteredNumbers[$0] ?? 0 },
                        setValue: { enteredNumbers[$0] = $1 },
                        label: { String($0) }
                    )
                }

                Button("Toon resultaten") {
                    isShowingResults = true
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
    }

    // 🔧 Invoervelden voor vormen/letters/cijfers
    func entryList<T: Hashable>(
        items: [T],
        getValue: @escaping (T) -> Int,
        setValue: @escaping (T, Int) -> Void,
        label: @escaping (T) -> String
    ) -> some View {
        List(items, id: \.self) { item in
            HStack {
                Text(label(item) + ":")
                Spacer()
                TextField("0", text: Binding(
                    get: {
                        textInputs[item] ?? "\(getValue(item))"
                    },
                    set: { newText in
                        let filtered = newText.filter { $0.isNumber }
                        textInputs[item] = filtered
                        setValue(item, Int(filtered) ?? 0)
                    }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 60)
                .multilineTextAlignment(.trailing)

            }
        }
    }

    // 📊 Resultaten tonen
    func resultList(data: [(String, Int, Int)]) -> some View {
        List(data, id: \.0) { label, entered, actual in
            let correct = entered == actual
            let skipped = entered == 0 && actual == 0
            let color: Color = correct || skipped ? .green : .red

            HStack {
                Text(label + ":")
                Spacer()
                Text("\(entered)/\(actual)").foregroundColor(color)
            }
        }
    }
}
