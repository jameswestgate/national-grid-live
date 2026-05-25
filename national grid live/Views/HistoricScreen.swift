import SwiftUI

struct HistoricScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Historic")
                    .font(.largeTitle.bold())
                    .padding(.horizontal, 4)

                if let message = snapshotFailureMessage {
                    OfflineBanner(message: message) {
                        Task { await store.refresh() }
                    }
                }

                if let live = store.live, let snapshot = store.snapshot {
                    PeriodSection(live: live, snapshot: snapshot)
                } else {
                    ProgressView()
                        .padding(.top, 60)
                }
            }
            .padding(16)
        }
        .background(Palette.pageBackground.ignoresSafeArea())
        .refreshable { await store.refresh() }
    }

    private var snapshotFailureMessage: String? {
        if case .failed(let m) = store.snapshotState, store.snapshot != nil { return m }
        return nil
    }
}

#Preview {
    HistoricScreen()
        .environment(GridStore.mock())
}
