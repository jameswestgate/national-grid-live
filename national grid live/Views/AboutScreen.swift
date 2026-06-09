import SwiftUI

struct AboutScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AboutSection(sources: store.snapshot?.sources)
                    TransitionSection()
                }
                .padding(16)
            }
            .washBackground()
            .navigationTitle("About")
        }
    }
}

#Preview {
    AboutScreen()
        .environment(GridStore.mock())
}
