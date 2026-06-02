import SwiftUI
import UIKit

struct ContentView: View {
    // Honour a `-startTab live|historic|about` launch argument (parsed into
    // UserDefaults by the system) so a chosen tab can be deep-linked at launch.
    @State private var selection: String = UserDefaults.standard.string(forKey: "startTab") ?? "live"
    @AppStorage(AppSettings.themeKey) private var theme: AppTheme = .system

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: "live") {
                LiveScreen()
            } label: {
                Label { Text("Live") } icon: { Image(uiImage: Self.tabIcon("bolt.fill")) }
            }
            Tab(value: "historic") {
                HistoricScreen()
            } label: {
                Label { Text("Historic") } icon: { Image(uiImage: Self.tabIcon("chart.xyaxis.line")) }
            }
            Tab(value: "about", role: .search) {
                AboutScreen()
            } label: {
                Label { Text("About") } icon: { Image(uiImage: Self.tabIcon("info.circle")) }
            }
        }
        .preferredColorScheme(theme.colorScheme)
    }

    /// Tab icons at a slightly smaller point size than the system default —
    /// a symbol-configured UIImage keeps its size inside the tab bar, where
    /// SwiftUI font modifiers are ignored.
    private static func tabIcon(_ name: String) -> UIImage {
        UIImage(
            systemName: name,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        ) ?? UIImage()
    }
}

#Preview {
    ContentView()
        .environment(GridStore.mock())
}
