import WidgetKit

struct SimpleEntry: TimelineEntry {
    let date: Date
    let smriti: Int
    let roshan: Int

    init(date: Date = Date(), data: CounterData) {
        self.date = date
        self.smriti = data.smriti
        self.roshan = data.roshan
    }

    init(date: Date, smriti: Int, roshan: Int) {
        self.date = date
        self.smriti = smriti
        self.roshan = roshan
    }
}

struct JobCounterTimelineProvider: TimelineProvider {
    private let localManager = LocalCounterManager()

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: .zero)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let timeline = Timeline(entries: [makeEntry()], policy: .never)
        completion(timeline)
    }

    private func makeEntry() -> SimpleEntry {
        // Reads CounterData from the App Group UserDefaults via LocalCounterManager.
        SimpleEntry(date: Date(), data: localManager.data)
    }
}
