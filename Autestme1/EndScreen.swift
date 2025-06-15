// EndScreen.swift (resultaat kleuren correct tonen bij 0/0)
import SwiftUI

struct EndScreen: View {
    @Binding var shapeCounts: [ShapeType: Int]
    let dismissAction: () -> Void
    let restartAction: () -> Void
    @Binding var gameLogic: GameLogic
    @Binding var navigationPath: NavigationPath

    @State private var enteredCounts: [ShapeType: Int] = [:]
    @State private var isShowingResults = false
    @FocusState private var focusedShape: ShapeType?
    @State private var selectedField: ShapeType? = nil

    private var totalCorrect: Int {
        shapeCounts.reduce(0) { result, pair in
            let entered = enteredCounts[pair.key] ?? 0
            return result + (entered == pair.value ? 1 : 0)
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

                List(shapeCounts.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \ .key) { shape, actual in
                    let entered = enteredCounts[shape] ?? 0
                    let isCorrect = entered == actual
                    let isSkipped = actual == 0 && entered == 0
                    let color: Color = isCorrect || isSkipped ? .green : .red

                    HStack {
                        Text("\(shape.displayName):")
                        Spacer()
                        Text("\(entered)/\(actual)")
                            .foregroundColor(color)
                    }
                }
                .padding()

                Text("Score: \(totalCorrect)/\(shapeCounts.count)")
                    .font(.title2)
                    .padding()

                Button(action: {
                    gameLogic.reset()
                    navigationPath.removeLast(navigationPath.count)
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

                List(ShapeType.allCases, id: \ .self) { shape in
                    HStack {
                        Text("\(shape.displayName):")
                        Spacer()
                        TextField("0", text: Binding(
                            get: {
                                if let value = enteredCounts[shape] {
                                    return String(value)
                                } else {
                                    return ""
                                }
                            },
                            set: { newValue in
                                if let value = Int(newValue.filter { $0.isNumber }) {
                                    enteredCounts[shape] = value
                                } else {
                                    enteredCounts[shape] = 0
                                }
                            }
                        ))
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedShape, equals: shape)
                        .submitLabel(.next)
                        .onTapGesture {
                            selectedField = shape
                            focusedShape = shape
                        }
                        .onChange(of: focusedShape) { newFocus in
                            if newFocus == shape {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    selectedField = shape
                                }
                            }
                        }
                        .onAppear {
                            if shape == ShapeType.allCases.first {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    focusedShape = shape
                                }
                            }
                        }
                        .background(
                            GeometryReader { geo in
                                Color.clear.onChange(of: selectedField) { target in
                                    if target == shape {
                                        UITextField.appearance().clearButtonMode = .never
                                        UITextField.appearance().tintColor = .clear
                                    }
                                }
                            }
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(focusedShape == shape ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
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

