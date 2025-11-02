import SwiftUI

struct NavigationViewWrapper: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            StartScreen(navigationPath: $path)
        }
    }
}
