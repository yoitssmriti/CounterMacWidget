import Foundation
import FirebaseCore
import FirebaseFirestore
import WidgetKit

final class FirestoreSyncService {
    static let didUpdateNotification = Notification.Name("FirestoreSyncService.didUpdate")

    private let localManager: LocalCounterManager
    private var listener: ListenerRegistration?

    private var competitionDocument: DocumentReference? {
        guard FirebaseApp.app() != nil else { return nil }
        // Ensure memory-cache settings are applied before the first Firestore use.
        _ = FirebaseBootstrap.configureIfPossible()
        return Firestore.firestore().collection("counters").document("competition")
    }

    init(localManager: LocalCounterManager = LocalCounterManager()) {
        self.localManager = localManager
    }

    deinit {
        stopListening()
    }

    /// Writes both counts to `counters/competition`.
    func pushCountsToCloud(myCount: Int, partnerCount: Int) {
        guard let competitionDocument else {
            print("Firestore push skipped: Firebase is not configured.")
            return
        }

        let payload: [String: Any] = [
            "myCount": myCount,
            "partnerCount": partnerCount,
        ]

        competitionDocument.setData(payload, merge: true) { error in
            if let error {
                print("Firestore push failed: \(error.localizedDescription)")
            } else {
                print("Firestore push ok: my=\(myCount) partner=\(partnerCount)")
            }
        }
    }

    /// Listens for remote changes, mirrors them into `LocalCounterManager`, and notifies the app.
    func listenForCloudUpdates() {
        listener?.remove()

        guard let competitionDocument else {
            print("Firestore listener skipped: Firebase is not configured.")
            return
        }

        print("Firestore listener attaching to counters/competition")

        listener = competitionDocument.addSnapshotListener { [weak self] snapshot, error in
            self?.applyRemoteSnapshot(snapshot, error: error)
        }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    private func applyRemoteSnapshot(_ snapshot: DocumentSnapshot?, error: Error?) {
        if let error {
            print("Firestore listener error: \(error.localizedDescription)")
            return
        }

        guard let snapshot else { return }

        guard snapshot.exists, let data = snapshot.data() else {
            print("Firestore counters/competition is missing — create it in the Firebase console.")
            return
        }

        let myCount = Self.intValue(data["myCount"])
        let partnerCount = Self.intValue(data["partnerCount"])
        let updated = CounterData(myCount: myCount, partnerCount: partnerCount)

        print("Firestore snapshot: my=\(myCount) partner=\(partnerCount) (raw my=\(String(describing: data["myCount"])) partner=\(String(describing: data["partnerCount"])))")

        // Always publish so the UI refreshes even when local already matched a failed earlier read.
        localManager.data = updated
        WidgetCenter.shared.reloadAllTimelines()

        NotificationCenter.default.post(
            name: Self.didUpdateNotification,
            object: self,
            userInfo: ["counterData": updated]
        )
    }

    /// Firestore may box numbers as Int, Int64, Double, or NSNumber — `as? Int` alone often fails.
    private static func intValue(_ raw: Any?) -> Int {
        switch raw {
        case let value as Int:
            return value
        case let value as Int64:
            return Int(value)
        case let value as Double:
            return Int(value)
        case let value as Float:
            return Int(value)
        case let value as NSNumber:
            return value.intValue
        default:
            return 0
        }
    }
}
