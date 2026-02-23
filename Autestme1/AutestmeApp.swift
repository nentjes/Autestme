import SwiftUI
import FirebaseCore

@main
struct AutestmeApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationViewWrapper()
        }
    }
}
