import SwiftUI

struct LiveScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
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
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    }
                }
                .padding(16)
            }
            .washBackground()
            .navigationTitle("Live")
            .refreshable { await store.refresh() }
        }
    }

    private var liveFailureMessage: String? {
        if case .failed(let m) = store.liveState, store.live != nil { return m }
        return nil
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        // 24-hour clock, no am/pm (e.g. "09:05", "13:45").
        f.locale = Locale(identifier: "en_GB")
        f.dateFormat = "HH:mm"
        return f
    }()
}

#Preview {
    LiveScreen()
        .environment(GridStore.mock())
}
