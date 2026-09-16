import Foundation

struct CounterData: Codable, Equatable {
    var smriti: Int
    var roshan: Int

    static let zero = CounterData(smriti: 0, roshan: 0)

    init(smriti: Int, roshan: Int) {
        self.smriti = smriti
        self.roshan = roshan
    }

    private enum CodingKeys: String, CodingKey {
        case smriti, roshan
        // Legacy keys from before the rename; read-only fallback.
        case myCount, partnerCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        smriti = try container.decodeIfPresent(Int.self, forKey: .smriti)
            ?? container.decodeIfPresent(Int.self, forKey: .myCount)
            ?? 0
        roshan = try container.decodeIfPresent(Int.self, forKey: .roshan)
            ?? container.decodeIfPresent(Int.self, forKey: .partnerCount)
            ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(smriti, forKey: .smriti)
        try container.encode(roshan, forKey: .roshan)
    }
}

final class LocalCounterManager {
    private static let storageKey = "counterData"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = AppGroup.shared) {
        self.defaults = defaults
    }

    var data: CounterData {
        get {
            guard
                let defaults,
                let stored = defaults.data(forKey: Self.storageKey),
                let decoded = try? JSONDecoder().decode(CounterData.self, from: stored)
            else {
                return .zero
            }
            return decoded
        }
        set {
            guard let defaults,
                  let encoded = try? JSONEncoder().encode(newValue)
            else {
                return
            }
            defaults.set(encoded, forKey: Self.storageKey)
        }
    }

    @discardableResult
    func incrementSmriti() -> CounterData {
        var current = data
        current.smriti += 1
        data = current
        return current
    }

    @discardableResult
    func decrementSmriti() -> CounterData {
        var current = data
        current.smriti = max(0, current.smriti - 1)
        data = current
        return current
    }

    @discardableResult
    func incrementRoshan() -> CounterData {
        var current = data
        current.roshan += 1
        data = current
        return current
    }

    @discardableResult
    func decrementRoshan() -> CounterData {
        var current = data
        current.roshan = max(0, current.roshan - 1)
        data = current
        return current
    }
}
