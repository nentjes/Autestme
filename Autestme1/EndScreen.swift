import SwiftUI

struct EndScreen: View {
    @Binding var shapeCounts: [ShapeType: Int]
    let dismissAction: () -> Void
    let restartAction: () -> Void
    @Binding var gameLogic: GameLogic
    
    @State private var enteredCounts: [ShapeType: Int] = [:]
    @State private var isShowingResults = false
    @Environment(\.presentationMode) var presentationMode

    private var totalCorrect: Int {
        shapeCounts.reduce(0) { result, shapeCountPair in
            let (shape, count) = shapeCountPair
            let enteredCount = enteredCounts[shape] ?? 0
            return result + (enteredCount == count ? 1 : 0)
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

                List(shapeCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { shape, count in
                    HStack {
                        Text("\(shape.displayName):")
                        Spacer()
                        Text("\(enteredCounts[shape] ?? 0) / \(count)")
                            .foregroundColor(enteredCounts[shape] == count ? .green : .red)
                    }
                }
                .padding()

                Text("Score: \(totalCorrect)/\(shapeCounts.count)")
                    .font(.title2)
                    .padding()

                Button(action: {
                    gameLogic.reset()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Terug naar start")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            } else {
                Text("Voer het aantal geziene vormen in:")
                    .font(.title)
                    .padding()

                List(ShapeType.allCases, id: \.self) { shape in
                    HStack {
                        Text("\(shape.displayName):")
                        Spacer()
                        TextField("0", text: Binding(
                            get: { String(enteredCounts[shape] ?? 0) },
                            set: { enteredCounts[shape] = Int($0) ?? 0 }
                        ))
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                    }
                }
                .padding()

                Button(action: { isShowingResults = true }) {
                    Text("Toon resultaten")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

