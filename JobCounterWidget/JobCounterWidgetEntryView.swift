import WidgetKit
import SwiftUI
import AppIntents

struct JobCounterWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        HStack(spacing: 12) {
            countColumn(
                title: "Smriti's Applications",
                count: entry.smriti,
                decrementIntent: DecrementSmritiIntent(),
                incrementIntent: IncrementSmritiIntent()
            )

            countColumn(
                title: "Roshan's Applications",
                count: entry.roshan,
                decrementIntent: DecrementRoshanIntent(),
                incrementIntent: IncrementRoshanIntent()
            )
        }
        .padding(12)
        // Keep labels/counts visible when macOS dims/redacts inactive desktop widgets
        // (otherwise Text is replaced with empty gray placeholder bars).
        .unredacted()
        .containerBackground(for: .widget) {
            Color(nsColor: .windowBackgroundColor)
        }
    }

    private func countColumn(
        title: String,
        count: Int,
        decrementIntent: some AppIntent,
        incrementIntent: some AppIntent
    ) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(count)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.primary)

            HStack(spacing: 14) {
                Button(intent: decrementIntent) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.secondary)
                }
                .buttonStyle(.plain)

                Button(intent: incrementIntent) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.08))
        }
    }
}
