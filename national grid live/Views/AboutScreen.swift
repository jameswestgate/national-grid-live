import SwiftUI

struct AboutScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TransitionSection()
                    AboutSection(sources: store.snapshot?.sources)
                }
                .padding(16)
            }
            .background(Palette.pageBackground.ignoresSafeArea())
            .navigationTitle("About")
        }
    }
}

#Preview {
    AboutScreen()
        .environment(GridStore.mock())
}
