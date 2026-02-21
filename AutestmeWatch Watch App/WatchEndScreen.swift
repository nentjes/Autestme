import SwiftUI
import WatchKit

struct WatchEndScreen: View {
    @ObservedObject var gameLogic: WatchGameLogic
    let shapeCounts: [WatchShapeType: Int]
    @Binding var navigationPath: NavigationPath

    @State private var enteredValues: [WatchShapeType: Int] = [:]
    @State private var isShowingResults = false
    @State private var currentItemIndex = 0

    /// Only shapes that actually appeared during the game
    private var activeShapes: [WatchShapeType] {
        shapeCounts
            .filter { $0.value > 0 }
            .map { $0.key }
            .sorted { $0.rawValue < $1.rawValue }
    }

    private var totalCorrect: Int {
        activeShapes.reduce(0) { acc, shape in
            let entered = enteredValues[shape] ?? 0
            let actual = shapeCounts[shape] ?? 0
            return acc + (entered == actual ? 1 : 0)
        }
    }

    var body: some View {
        if isShowingResults {
            resultsView
        } else {
            inputView
        }
    }

    // MARK: - Input View (one shape at a time with Digital Crown)

    private var inputView: some View {
        VStack(spacing: 6) {
            Text(NSLocalizedString("end_screen_input_prompt", comment: ""))
                .font(.caption2)
                .multilineTextAlignment(.center)

            if currentItemIndex < activeShapes.count {
                let shape = activeShapes[currentItemIndex]

                // Shape icon + name
                HStack(spacing: 6) {
                    shape.shapeView()
                        .foregroundColor(shape.color)
                        .frame(width: 30, height: 30)
                    Text(shape.displayName)
                        .font(.headline)
                }

                // Digital Crown wheel picker
                let binding = Binding<Int>(
                    get: { enteredValues[shape] ?? 0 },
                    set: { enteredValues[shape] = $0 }
                )

                Picker(selection: binding, label: Text("")) {
                    ForEach(0...99, id: \.self) { num in
                        Text("\(num)").tag(num)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 60)

                // Progress indicator
                Text("\(currentItemIndex + 1) / \(activeShapes.count)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                HStack {
                    // Back button
                    if currentItemIndex > 0 {
                        Button(action: { currentItemIndex -= 1 }) {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    // Next / Show results
                    if currentItemIndex < activeShapes.count - 1 {
                        Button(action: {
                            WKInterfaceDevice.current().play(.click)
                            currentItemIndex += 1
                        }) {
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(action: showResults) {
                            Text(NSLocalizedString("end_screen_show_results_button", comment: ""))
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text(NSLocalizedString("end_screen_results_title", comment: ""))
                    .font(.headline)

                ForEach(activeShapes, id: \.self) { shape in
                    let entered = enteredValues[shape] ?? 0
                    let actual = shapeCounts[shape] ?? 0
                    let correct = entered == actual

                    HStack {
                        shape.shapeView()
                            .foregroundColor(shape.color)
                            .frame(width: 20, height: 20)

                        Text(shape.displayName)
                            .font(.caption)

                        Spacer()

                        Text(String(
                            format: NSLocalizedString("end_screen_result_format", comment: ""),
                            "\(entered)", "\(actual)"
                        ))
                        .font(.caption2)
                        .foregroundColor(correct ? .green : .red)
                    }
                }

                Divider()

                Text(String(
                    format: NSLocalizedString("end_screen_score_label", comment: ""),
                    "\(totalCorrect)"
                ))
                .font(.title3)
                .bold()

                Button(NSLocalizedString("end_screen_back_button", comment: "")) {
                    // Pop all the way back to the root
                    navigationPath.removeLast(navigationPath.count)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Actions

    private func showResults() {
        isShowingResults = true

        // Update highscore
        let current = WatchGameLogic.getHighScore()
        if totalCorrect > current {
            WatchGameLogic.setHighScore(totalCorrect)
        }

        // Haptic for result
        WKInterfaceDevice.current().play(totalCorrect > 0 ? .success : .failure)
    }
}
