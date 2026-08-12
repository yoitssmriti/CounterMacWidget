import Foundation
import FirebaseCore
import FirebaseFirestore

enum FirebaseBootstrap {
    private static var didConfigureFirestoreSettings = false

    /// Configures Firebase when `GoogleService-Info.plist` is present. Safe to call from app or intents.
    @discardableResult
    static func configureIfPossible() -> Bool {
        if FirebaseApp.app() != nil {
            configureFirestoreIfNeeded()
            return true
        }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return false
        }

        FirebaseApp.configure()
        configureFirestoreIfNeeded()
        return FirebaseApp.app() != nil
    }

    /// Sandboxed macOS builds crash in `FirestoreClient::Initialize` when LevelDB persistence
    /// can't take an exclusive lock (common with App Sandbox, or a second JobCounter still running).
    /// Memory cache avoids that; cloud sync and local UserDefaults still work.
    private static func configureFirestoreIfNeeded() {
        guard !didConfigureFirestoreSettings, FirebaseApp.app() != nil else { return }
        didConfigureFirestoreSettings = true

        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
    }
}
