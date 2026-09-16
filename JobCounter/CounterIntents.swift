import AppIntents
import WidgetKit

enum CounterIntentSupport {
    static func apply(_ mutate: (LocalCounterManager) -> CounterData) {
        let manager = LocalCounterManager()
        let updated = mutate(manager)

        // Firebase sync is app-only — the widget target defines JOBCOUNTER_WIDGET and
        // does not compile FirestoreSyncService / FirebaseBootstrap.
        #if !JOBCOUNTER_WIDGET
        FirebaseBootstrap.configureIfPossible()
        FirestoreSyncService(localManager: manager)
            .pushCountsToCloud(updated)
        #endif

        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct IncrementSmritiIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Smriti's Count"
    static var description = IntentDescription("Adds one to Smriti's Applications.")

    func perform() async throws -> some IntentResult {
        CounterIntentSupport.apply { $0.incrementSmriti() }
        return .result()
    }
}

struct DecrementSmritiIntent: AppIntent {
    static var title: LocalizedStringResource = "Decrement Smriti's Count"
    static var description = IntentDescription("Subtracts one from Smriti's Applications.")

    func perform() async throws -> some IntentResult {
        CounterIntentSupport.apply { $0.decrementSmriti() }
        return .result()
    }
}

struct IncrementRoshanIntent: AppIntent {
    static var title: LocalizedStringResource = "Increment Roshan's Count"
    static var description = IntentDescription("Adds one to Roshan's Applications.")

    func perform() async throws -> some IntentResult {
        CounterIntentSupport.apply { $0.incrementRoshan() }
        return .result()
    }
}

struct DecrementRoshanIntent: AppIntent {
    static var title: LocalizedStringResource = "Decrement Roshan's Count"
    static var description = IntentDescription("Subtracts one from Roshan's Applications.")

    func perform() async throws -> some IntentResult {
        CounterIntentSupport.apply { $0.decrementRoshan() }
        return .result()
    }
}
