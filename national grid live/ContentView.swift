import SwiftUI

struct ContentView: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section("Live") { liveSection }
                Section("Snapshot") { snapshotSection }
                Section("State") { stateSection }
            }
            .navigationTitle("National Grid: Live")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        Task { await store.refresh() }
                    }
                }
            }
            .task { await store.refresh() }
        }
    }

    @ViewBuilder
    private var liveSection: some View {
        if let live = store.live {
            LabeledContent("Price",      value: String(format: "£%.2f/MWh", live.price))
            LabeledContent("Emissions",  value: String(format: "%.0fg/kWh", live.emissions))
            LabeledContent("Demand",     value: String(format: "%.1f GW", live.demand))
            LabeledContent("Generation", value: String(format: "%.1f GW", live.generation))
            LabeledContent("Transfers",  value: String(format: "%.1f GW", live.transfers))
        } else {
            Text("No live data yet").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var snapshotSection: some View {
        if let snap = store.snapshot {
            LabeledContent("Schema",   value: "v\(snap.schemaVersion)")
            LabeledContent("Year",     value: "\(snap.year.from) → \(snap.year.to) (\(snap.year.count))")
            LabeledContent("All time", value: "\(snap.allTime.from) → \(snap.allTime.to) (\(snap.allTime.count))")
        } else {
            Text("No snapshot yet").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var stateSection: some View {
        LabeledContent("Live")     { stateLabel(store.liveState) }
        LabeledContent("Snapshot") { stateLabel(store.snapshotState) }
    }

    @ViewBuilder
    private func stateLabel(_ s: GridStore.LoadState) -> some View {
        switch s {
        case .idle:           Text("idle").foregroundStyle(.secondary)
        case .loading:        Text("loading…").foregroundStyle(.secondary)
        case .loaded:         Text("loaded").foregroundStyle(.green)
        case .failed(let m):  Text(m).foregroundStyle(.red)
        }
    }
}

#Preview {
    ContentView()
        .environment(GridStore.mock())
}
