import Foundation
import BackgroundTasks
import WidgetKit
import os

/// Opportunistic background refresh: iOS wakes the app (BGAppRefreshTask), we
/// do the light current-only fetch, keep the widget snapshot warm and evaluate
/// the notification alerts. Timing is entirely up to the system — typically a
/// handful of runs a day for a regularly-used app, none if the user force-quits.
enum BackgroundRefresh {
    /// Must match BGTaskSchedulerPermittedIdentifiers in Info.plist.
    static let taskIdentifier = "org.crainiate.national-grid-live.refresh"

    private static let log = Logger(
        subsystem: "org.crainiate.national-grid-live", category: "background")

    /// Submit (or replace) the pending refresh request. Called whenever the app
    /// goes to background and again at the start of each background run, so the
    /// chain continues even if a run is expired or crashes.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            log.debug("scheduled background refresh")
        } catch {
            // Expected on the Simulator (unsupported) — never fatal.
            log.info("could not schedule background refresh: \(error.localizedDescription)")
        }
    }

    /// Body of the `.backgroundTask(.appRefresh(...))` handler. Budget is ~30s;
    /// expiration cancels the task, which propagates through the URLSession
    /// calls — everything below unwinds cleanly on cancellation.
    static func run() async {
        schedule()   // keep the chain alive before doing anything else
        log.info("background refresh started")

        guard let aggregator = try? LiveDataAggregator(),
              let grid = try? await aggregator.fetchCurrentOnly() else {
            log.info("background fetch failed or was cancelled")
            return
        }

        // Same side benefit as the widget's own fallback fetch: a fresh shared
        // snapshot keeps the Lock/Home Screen widgets current while the app is closed.
        if let cache = try? JSONCache<LiveGrid>(
            filename: AppGroup.snapshotFilename, appGroup: AppGroup.identifier) {
            cache.write(grid)
        }
        WidgetCenter.shared.reloadAllTimelines()

        await GridAlertCenter().evaluateAndNotify(grid: grid)
        log.info("background refresh finished")
    }
}
