import SwiftUI

@main
struct JobCounterApp: App {
    /// Declared before `appDelegate` so Firebase is ready before AppDelegate is created.
    private let firebaseReady = FirebaseBootstrap.configureIfPossible()

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        _ = firebaseReady
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
