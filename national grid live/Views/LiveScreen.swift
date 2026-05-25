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
                    StatusBarView(
                        stats: live.current.asAverages,
                        headline: ("Time", Self.timeFormatter.string(from: live.current.asOf))
                    )
                    LatestSection(stats: live.current.asAverages)
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

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mma"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f
    }()
}

#Preview {
    LiveScreen()
        .environment(GridStore.mock())
}
