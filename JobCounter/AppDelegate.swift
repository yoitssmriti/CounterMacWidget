import AppKit
import FirebaseCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var syncService = FirestoreSyncService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        if FirebaseBootstrap.configureIfPossible() {
            print("Firebase initialized successfully.")
            syncService.listenForCloudUpdates()
        } else {
            print("Firebase was not configured: GoogleService-Info.plist not found. Local counting still works.")
        }
    }
}
