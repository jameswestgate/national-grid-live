import SwiftUI

@main
struct national_grid_liveApp: App {
    @State private var store = GridStore.mock()

    init() {
        FontRegistry.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .font(.appSerif(.body))
        }
    }
}
