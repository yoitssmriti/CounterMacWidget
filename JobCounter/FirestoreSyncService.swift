import Foundation
import FirebaseCore
import FirebaseFirestore
import WidgetKit

final class FirestoreSyncService {
    static let didUpdateNotification = Notification.Name("FirestoreSyncService.didUpdate")

    private let localManager: LocalCounterManager
    private var listener: ListenerRegistration?
    private var defaultsObserver: DefaultsKeyObserver?
    /// Last value received from (or mirrored into) the cloud, used to tell
    /// widget-made local changes apart from our own cloud-snapshot writes.
    private var lastCloudData: CounterData?

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
    func pushCountsToCloud(_ counts: CounterData) {
        guard let competitionDocument else {
            print("Firestore push skipped: Firebase is not configured.")
            return
        }

        let payload: [String: Any] = [
            "smriti": counts.smriti,
            "roshan": counts.roshan,
        ]

        competitionDocument.setData(payload, merge: true) { error in
            if let error {
                print("Firestore push failed: \(error.localizedDescription)")
            } else {
                print("Firestore push ok: smriti=\(counts.smriti) roshan=\(counts.roshan)")
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

        startObservingLocalChanges()
    }

    func stopListening() {
        listener?.remove()
        listener = nil
        defaultsObserver = nil
    }

    /// The widget can only write to the shared App Group (it has no Firebase),
    /// so the app watches that storage and forwards widget-made changes to the
    /// cloud. UserDefaults KVO fires across processes for shared suites.
    private func startObservingLocalChanges() {
        guard defaultsObserver == nil else { return }

        defaultsObserver = DefaultsKeyObserver(
            defaults: AppGroup.shared,
            key: LocalCounterManager.storageKey
        ) { [weak self] in
            self?.handleLocalChange()
        }
    }

    private func handleLocalChange() {
        let current = localManager.data
        guard current != lastCloudData else { return }

        print("Local change detected (widget?): smriti=\(current.smriti) roshan=\(current.roshan) — pushing to cloud")
        pushCountsToCloud(current)

        NotificationCenter.default.post(
            name: Self.didUpdateNotification,
            object: self,
            userInfo: ["counterData": current]
        )
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

        // Fall back to the legacy myCount/partnerCount fields so counts survive the rename.
        let smriti = Self.intValue(data["smriti"] ?? data["myCount"])
        let roshan = Self.intValue(data["roshan"] ?? data["partnerCount"])
        let updated = CounterData(smriti: smriti, roshan: roshan)

        print("Firestore snapshot: smriti=\(smriti) roshan=\(roshan)")

        // Record the cloud value BEFORE the local write: KVO fires synchronously in
        // this process, and handleLocalChange must not echo this write back to Firestore.
        lastCloudData = updated

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

/// KVO wrapper for one UserDefaults key. For App Group suites the notification
/// also fires when another process (the widget) changes the key.
final class DefaultsKeyObserver: NSObject {
    private let defaults: UserDefaults
    private let key: String
    private let onChange: () -> Void

    init(defaults: UserDefaults, key: String, onChange: @escaping () -> Void) {
        self.defaults = defaults
        self.key = key
        self.onChange = onChange
        super.init()
        defaults.addObserver(self, forKeyPath: key, options: [.new], context: nil)
    }

    deinit {
        defaults.removeObserver(self, forKeyPath: key)
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == key else { return }
        onChange()
    }
}
