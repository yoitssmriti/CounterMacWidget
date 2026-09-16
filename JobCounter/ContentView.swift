import SwiftUI

struct ContentView: View {
    @State private var counter = CounterData.zero

    private let manager = LocalCounterManager()
    private let syncService = FirestoreSyncService()

    var body: some View {
        VStack(spacing: 24) {
            Text("Job Counter Competition")
                .font(.largeTitle)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                counterCard(
                    title: "Smriti's Applications",
                    count: counter.smriti,
                    onDecrement: {
                        counter = apply { $0.decrementSmriti() }
                    },
                    onIncrement: {
                        counter = apply { $0.incrementSmriti() }
                    }
                )

                counterCard(
                    title: "Roshan's Applications",
                    count: counter.roshan,
                    onDecrement: {
                        counter = apply { $0.decrementRoshan() }
                    },
                    onIncrement: {
                        counter = apply { $0.incrementRoshan() }
                    }
                )
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if !AppGroup.isAvailable {
                print("Warning: App Group not available — counts use standard defaults until Signing registers \(AppGroup.suiteName)")
            }
            counter = manager.data
            syncService.listenForCloudUpdates()
        }
        .onReceive(NotificationCenter.default.publisher(for: FirestoreSyncService.didUpdateNotification)) { notification in
            if let updated = notification.userInfo?["counterData"] as? CounterData {
                counter = updated
            } else {
                counter = manager.data
            }
        }
    }

    private func apply(_ mutate: (LocalCounterManager) -> CounterData) -> CounterData {
        let updated = mutate(manager)
        syncService.pushCountsToCloud(updated)
        return updated
    }

    private func counterCard(
        title: String,
        count: Int,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)

            Text("\(count)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                Button(action: onDecrement) {
                    Image(systemName: "minus")
                        .font(.title2.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.bordered)
                .disabled(count == 0)

                Button(action: onIncrement) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ContentView()
}
