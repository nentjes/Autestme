import SwiftUI
import FirebaseCore
import FirebaseAppCheck

class AutestmeAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
        // Simulator/Debug builds can't perform real App Attest — the debug
        // provider is registered for the app's debug token in the Firebase
        // Console instead.
        //
        // We pin this via setenv() rather than relying solely on the
        // Xcode scheme's "FIRAAppCheckDebugToken" environment variable:
        // that variable was confirmed (via a direct curl exchange against
        // Firebase's backend) to be registered and valid, yet the app kept
        // sending a different, unregistered token — the scheme env var
        // wasn't reliably reaching the process. Setting it here in code
        // removes that ambiguity entirely.
        //
        // TODO: once reward claims are confirmed working end-to-end, swap
        // this literal for a value loaded from an untracked local config
        // (or re-investigate why the scheme env var wasn't picked up) so
        // this isn't a hardcoded value in source control long-term.
        setenv("FIRAAppCheckDebugToken", "567A47FD-E8ED-4299-A0A1-7162B2F52DA7", 1)
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
