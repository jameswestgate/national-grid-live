import SwiftUI

struct ContentView: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("The National Grid is the electric power transmission network for Great Britain")
                        .font(.appSerif(.subheadline))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if let live = store.live {
                        StatusBarView(live: live)
                        LatestSection(live: live)
                    } else {
                        ProgressView()
                            .padding(.top, 60)
                    }
                }
                .padding(16)
            }
            .background(Palette.pageBackground.ignoresSafeArea())
            .refreshable { await store.refresh() }
            .navigationTitle("National Grid: Live")
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
            .task { await store.refresh() }
        }
    }
}

#Preview {
    ContentView()
        .environment(GridStore.mock())
        .preferredColorScheme(.dark)
}
