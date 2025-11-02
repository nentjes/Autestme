import SwiftUI

struct EndScreen: View {
    @Binding var shapeCounts: [ShapeType: Int]
    let dismissAction: () -> Void
    let restartAction: () -> Void
    @ObservedObject var gameLogic: GameLogic
    @Binding var navigationPath: NavigationPath

    @State private var enteredShapes: [ShapeType: Int] = [:]
    @State private var enteredLetters: [Character: Int] = [:]
    @State private var enteredNumbers: [Int: Int] = [:]
    @State private var isShowingResults = false
    @State private var textInputs: [AnyHashable: String] = [:]
    @FocusState private var focusedField: AnyHashable? // <-- HIER IS DE FOCUS

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
            Text("end_screen_title") // <-- Gelokaliseerd
                .font(.largeTitle)
                .padding()

            if isShowingResults {
                Text("end_screen_results_title") // <-- Gelokaliseerd
                    .font(.title)
                    .padding()

                switch gameLogic.gameVersion {
                case .shapes:
                    resultList(data: shapeCounts.map { ($0.key.displayName, enteredShapes[$0.key] ?? 0, $0.value) })
                case .letters:
                    resultList(data: gameLogic.letterCounts.filter { $0.value > 0 }
                        .sorted(by: {$0.key < $1.key}) // <-- HIER IS DE SORTERING
                        .map { (String($0.key), enteredLetters[$0.key] ?? 0, $0.value) })
                case .numbers:
                    resultList(data: gameLogic.numberCounts.filter { $0.value > 0 }
                        .sorted(by: {$0.key < $1.key}) // <-- HIER IS DE SORTERING
                        .map { (String($0.key), enteredNumbers[$0.key] ?? 0, $0.value) })
                }

                Text(String(format: NSLocalizedString("end_screen_score_label", comment: ""), "\(totalCorrect)"))
                    .font(.title2)
                    .padding()

                Button("end_screen_back_button") { // <-- Gelokaliseerd
                    gameLogic.reset()
                    navigationPath.removeLast(navigationPath.count)
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text("end_screen_input_prompt") // <-- Gelokaliseerd
                    .font(.title2)
                    .padding()

                switch gameLogic.gameVersion {
                case .shapes:
                    entryList(
                        items: shapeCounts.map { $0.key },
                        getValue: { enteredShapes[$0] ?? 0 },
                        setValue: { enteredShapes[$0] = $1 },
                        label: { $0.displayName },
                        focusState: $focusedField
                    )
                case .letters:
                    entryList(
                        items: gameLogic.letterCounts.filter { $0.value > 0 }.map { $0.key }.sorted(),
                        getValue: { enteredLetters[$0] ?? 0 },
                        setValue: { enteredLetters[$0] = $1 },
                        label: { String($0) },
                        focusState: $focusedField
                    )
                case .numbers:
                    entryList(
                        items: gameLogic.numberCounts.filter { $0.value > 0 }.map { $0.key }.sorted(),
                        getValue: { enteredNumbers[$0] ?? 0 },
                        setValue: { enteredNumbers[$0] = $1 },
                        label: { String($0) },
                        focusState: $focusedField
                    )
                }

                Button("end_screen_show_results_button") { // <-- Gelokaliseerd
                    isShowingResults = true
                    if totalCorrect > GameLogic.getHighScore(for: gameLogic.player, gameVersion: gameLogic.gameVersion) {
                        GameLogic.setHighScore(totalCorrect, for: gameLogic.player, gameVersion: gameLogic.gameVersion)
                    }
                }
                .font(.title2)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear { // <-- HIER IS DE AUTO-FOCUS LOGICA
            if !isShowingResults {
                var firstItem: AnyHashable?
                switch gameLogic.gameVersion {
                case .shapes:
                    firstItem = shapeCounts.map { $0.key }.first
                case .letters:
                    firstItem = gameLogic.letterCounts.filter { $0.value > 0 }.map { $0.key }.sorted().first
                case .numbers:
                    firstItem = gameLogic.numberCounts.filter { $0.value > 0 }.map { $0.key }.sorted().first
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focusedField = firstItem
                }
            }
        }
    }

    // 🔧 Invoervelden
    func entryList<T: Hashable>(
        items: [T],
        getValue: @escaping (T) -> Int,
        setValue: @escaping (T, Int) -> Void,
        label: @escaping (T) -> String,
        focusState: FocusState<AnyHashable?>.Binding
    ) -> some View {
        List(items, id: \.self) { item in
            HStack {
                Text(String(format: NSLocalizedString("end_screen_item_label", comment: ""), label(item)))
                Spacer()
                
                // HIER IS DE "0" PLACEHOLDER LOGICA
                TextField("end_screen_input_placeholder", text: Binding(
                    get: {
                        let value = getValue(item)
                        if value != 0 {
                            return "\(value)"
                        }
                        return "" // <-- Toon leeg veld als waarde 0 is
                    },
                    set: { newText in
                        let filtered = newText.filter { $0.isNumber }
                        textInputs[item] = filtered
                        setValue(item, Int(filtered) ?? 0) // Sla 0 op als veld leeg is
                    }
                ))
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 60)
                .multilineTextAlignment(.trailing)
                .focused(focusState, equals: item)
            }
        }
    }

    // 📊 Resultaten
    func resultList(data: [(String, Int, Int)]) -> some View {
        List(data, id: \.0) { label, entered, actual in
            let correct = entered == actual
            let skipped = entered == 0 && actual == 0
            let color: Color = correct || skipped ? .green : .red

            HStack {
                Text(String(format: NSLocalizedString("end_screen_item_label", comment: ""), label))
                Spacer()
                Text(String(format: NSLocalizedString("end_screen_result_format", comment: ""), "\(entered)", "\(actual)"))
                    .foregroundColor(color)
            }
        }
    }
}
