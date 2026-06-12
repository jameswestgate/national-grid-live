import SwiftUI
import UserNotifications

@main
struct national_grid_liveApp: App {
    @State private var store: GridStore
    @State private var scheduler: RefreshScheduler
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let store = AppConfig.default.makeStore()
        store.primeFromCache()
        _store = State(initialValue: store)
        _scheduler = State(initialValue: RefreshScheduler(store: store))
        // Show alert banners while the app is foregrounded (see GridAlerts).
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    switch phase {
                    case .active:    scheduler.start()
                    case .inactive, .background:
                        scheduler.stop()
                        BackgroundRefresh.schedule()
                    @unknown default: break
                    }
                }
        }
        .backgroundTask(.appRefresh(BackgroundRefresh.taskIdentifier)) {
            await BackgroundRefresh.run()
        }
    }
}
