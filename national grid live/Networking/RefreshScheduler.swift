import Foundation
import os

/// Refreshes the GridStore on a wall-clock cadence aligned to 5-minute
/// boundaries (matching Elexon's FUELINST publish rate). Designed to be
/// driven from `.onChange(of: scenePhase)` — `start()` on becoming active,
/// `stop()` on leaving foreground. Cancelling the task is safe.
@MainActor
final class RefreshScheduler {
    enum Cadence {
        case fiveMinutes
        var seconds: Int {
            switch self {
            case .fiveMinutes: 300
            }
        }
    }

    private let store: GridStore
    private let cadence: Cadence
    private var task: Task<Void, Never>?
    private let log = Logger(subsystem: "org.crainiate.national-grid-live", category: "scheduler")

    init(store: GridStore, cadence: Cadence = .fiveMinutes) {
        self.store = store
        self.cadence = cadence
    }

    /// Begin the refresh loop. Fires an immediate refresh, then waits until the
    /// next 5-minute boundary, then loops. No-op if already running.
    func start() {
        guard task == nil else { return }
        let store = self.store
        let cadence = self.cadence
        let log = self.log
        task = Task { @MainActor in
            log.info("scheduler.start")
            await store.refresh()
            while !Task.isCancelled {
                let delay = Self.secondsUntilNextBoundary(cadence: cadence)
                log.debug("scheduler.sleep seconds=\(delay)")
                do {
                    try await Task.sleep(for: .seconds(delay))
                } catch {
                    break
                }
                if Task.isCancelled { break }
                await store.refresh()
            }
            log.info("scheduler.stop")
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    /// Seconds from `reference` until the next clock boundary matching the cadence.
    /// e.g. cadence=5min, reference=09:51:23 → returns 217 (next boundary at 09:55:00).
    static func secondsUntilNextBoundary(cadence: Cadence, reference: Date = .now) -> Int {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.minute, .second], from: reference)
        let minute = comps.minute ?? 0
        let second = comps.second ?? 0
        let interval = cadence.seconds
        let secondsIntoInterval = ((minute * 60) + second) % interval
        let remaining = interval - secondsIntoInterval
        // Never less than 5 seconds — guards against tight loops when we happen to
        // wake up exactly on a boundary.
        return max(remaining, 5)
    }
}
