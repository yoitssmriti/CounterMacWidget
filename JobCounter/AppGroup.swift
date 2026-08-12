import Foundation

enum AppGroup {
    static let suiteName = "group.com.jobcounter.app"

    private static let resolved: (defaults: UserDefaults, usingAppGroup: Bool) = {
        if let suite = UserDefaults(suiteName: suiteName) {
            let probeKey = "__jobcounter_appgroup_probe__"
            let token = UUID().uuidString
            suite.set(token, forKey: probeKey)
            if suite.string(forKey: probeKey) == token {
                suite.removeObject(forKey: probeKey)
                return (suite, true)
            }
        }

        print("App Group \(suiteName) is unavailable; using standard UserDefaults. Widget sync won't work until App Groups are registered in Signing & Capabilities.")
        return (.standard, false)
    }()

    /// Shared defaults for app + widget. Falls back to `.standard` if the App Group isn't provisioned.
    static var shared: UserDefaults { resolved.defaults }

    static var isAvailable: Bool { resolved.usingAppGroup }
}
