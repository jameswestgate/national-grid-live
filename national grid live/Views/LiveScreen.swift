import SwiftUI

struct LiveScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Live")
                    .font(.largeTitle.bold())
                    .padding(.horizontal, 4)

                if let message = liveFailureMessage {
                    OfflineBanner(message: message) {
                        Task { await store.refresh() }
                    }
                }

                if let live = store.live {
                    StatusBarView(live: live.current)
                    LatestSection(live: live.current)
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

    private var liveFailureMessage: String? {
        if case .failed(let m) = store.liveState, store.live != nil { return m }
        return nil
    }
}

#Preview {
    LiveScreen()
        .environment(GridStore.mock())
}
