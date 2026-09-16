import WidgetKit
import SwiftUI

struct JobCounterWidget: Widget {
    let kind: String = "JobCounterWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: JobCounterTimelineProvider()) { entry in
            JobCounterWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Job Counter")
        .description("Tracks application counts.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    JobCounterWidget()
} timeline: {
    SimpleEntry(date: .now, smriti: 12, roshan: 9)
}
