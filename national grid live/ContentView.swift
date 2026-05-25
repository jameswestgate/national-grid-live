import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Live", systemImage: "bolt.fill") {
                LiveScreen()
            }
            Tab("Historic", systemImage: "chart.xyaxis.line") {
                HistoricScreen()
            }
            Tab("About", systemImage: "info.circle", role: .search) {
                AboutScreen()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(GridStore.mock())
}
