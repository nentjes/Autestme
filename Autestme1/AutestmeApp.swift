import SwiftUI
import FirebaseCore
import FirebaseAppCheck

class AutestmeAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        // Simulator/Debug builds can't perform real App Attest — the debug
        // provider is registered for the app's debug token in the Firebase
        // Console instead.
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app)
        #endif
    }
}

@main
struct AutestmeApp: App {
    init() {
        AppCheck.setAppCheckProviderFactory(AutestmeAppCheckProviderFactory())
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            NavigationViewWrapper()
        }
    }
}
