import SwiftUI

struct AboutScreen: View {
    @Environment(GridStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("About")
                    .font(.largeTitle.bold())
                    .padding(.horizontal, 4)

                TransitionSection()
                AboutSection(sources: store.snapshot?.sources)
            }
            .padding(16)
        }
        .background(Palette.pageBackground.ignoresSafeArea())
    }
}

#Preview {
    AboutScreen()
        .environment(GridStore.mock())
}
