import SwiftUI

struct HistoricScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 16) {
                            TransitionSection().frame(maxWidth: .infinity)
                            AboutSection(sources: store.snapshot?.sources).frame(maxWidth: .infinity)
                        }
                        VStack(spacing: 16) {
                            TransitionSection()
                            AboutSection(sources: store.snapshot?.sources)
                        }
                    }
                }
                .padding(16)
            }
            .background(Palette.pageBackground.ignoresSafeArea())
            .refreshable { await store.refresh() }
            .navigationTitle("Historic")
        }
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
