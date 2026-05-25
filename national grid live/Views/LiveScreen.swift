import SwiftUI

struct LiveScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("The National Grid is the electric power transmission network for Great Britain")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationTitle("Live")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(store.liveState == .loading)
                }
            }
        }
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
