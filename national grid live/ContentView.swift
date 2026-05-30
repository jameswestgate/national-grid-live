import SwiftUI

struct ContentView: View {
    // Honour a `-startTab live|historic|about` launch argument (parsed into
    // UserDefaults by the system) so a chosen tab can be deep-linked at launch.
    @State private var selection: String = UserDefaults.standard.string(forKey: "startTab") ?? "live"

    var body: some View {
        TabView(selection: $selection) {
            Tab("Live", systemImage: "bolt.fill", value: "live") {
                LiveScreen()
            }
            Tab("Historic", systemImage: "chart.xyaxis.line", value: "historic") {
                HistoricScreen()
            }
            Tab("About", systemImage: "info.circle", value: "about", role: .search) {
                AboutScreen()
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(GridStore.mock())
}
