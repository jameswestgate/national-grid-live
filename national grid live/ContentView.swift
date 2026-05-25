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
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
        .environment(GridStore.mock())
}
