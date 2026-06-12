import Foundation
import UserNotifications
import os

/// The five opt-in grid alerts (Settings → Notifications). Each fires at most
/// once per calendar day, from a local notification — there is no server; the
/// readings are checked when the app refreshes and opportunistically in the
/// background (`BackgroundRefresh`).
enum GridAlert: String, CaseIterable, Identifiable {
    case highCarbon
    case lowCarbon
    case highPrice
    case lowPrice
    case negativePrice

    // Fixed, opinionated thresholds. Strict comparisons; price/carbon readings
    // of exactly 0 are treated as "missing" by `triggers(on:)` below.
    static let highCarbonThreshold = 150.0   // g/kWh
    static let lowCarbonThreshold  = 50.0    // g/kWh
    static let highPriceThreshold  = 150.0   // £/MWh
    static let lowPriceThreshold   = 50.0    // £/MWh

    var id: String { rawValue }

    /// `@AppStorage`/UserDefaults key for this alert's toggle.
    var settingsKey: String {
        switch self {
        case .highCarbon:    AppSettings.alertHighCarbonKey
        case .lowCarbon:     AppSettings.alertLowCarbonKey
        case .highPrice:     AppSettings.alertHighPriceKey
        case .lowPrice:      AppSettings.alertLowPriceKey
        case .negativePrice: AppSettings.alertNegativePriceKey
        }
    }

    /// UserDefaults key recording when this alert last fired (the once-a-day throttle).
    var lastFiredKey: String { "alertLastFired.\(rawValue)" }

    /// Fixed per-type identifier so a repeat replaces the previous notification
    /// rather than stacking.
    var notificationIdentifier: String { "org.crainiate.national-grid-live.alert.\(rawValue)" }

    /// Whether the current reading crosses this alert's threshold. Zero values
    /// are skipped: the aggregator substitutes 0 when a price/carbon source is
    /// missing, so 0 is indistinguishable from "no data".
    func triggers(on grid: LiveGrid) -> Bool {
        switch self {
        case .highCarbon:    grid.emissions > Self.highCarbonThreshold
        case .lowCarbon:     grid.emissions > 0 && grid.emissions < Self.lowCarbonThreshold
        case .highPrice:     grid.price > Self.highPriceThreshold
        case .lowPrice:      grid.price != 0 && grid.price < Self.lowPriceThreshold && grid.price >= 0
        case .negativePrice: grid.price < 0
        }
    }

    func content(for grid: LiveGrid) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        switch self {
        case .highCarbon:
            content.title = "High carbon intensity"
            content.body = "Grid carbon intensity is \(Self.grams(grid.emissions)) g/kWh - above \(Int(Self.highCarbonThreshold))."
        case .lowCarbon:
            content.title = "Low carbon intensity"
            content.body = "Grid carbon intensity is \(Self.grams(grid.emissions)) g/kWh - below \(Int(Self.lowCarbonThreshold))."
        case .highPrice:
            content.title = "High electricity price"
            content.body = "The wholesale price is \(Self.pounds(grid.price)) per MWh - above £\(Int(Self.highPriceThreshold))."
        case .lowPrice:
            content.title = "Low electricity price"
            content.body = "The wholesale price is \(Self.pounds(grid.price)) per MWh - below £\(Int(Self.lowPriceThreshold))."
        case .negativePrice:
            content.title = "Negative electricity price"
            content.body = "The wholesale price is \(Self.pounds(grid.price)) per MWh - generators are paying to offload power."
        }
        content.sound = .default
        content.threadIdentifier = "grid-alerts"
        return content
    }

    private static func grams(_ value: Double) -> String { String(format: "%.0f", value) }

    private static func pounds(_ value: Double) -> String {
        value < 0 ? String(format: "-£%.2f", abs(value)) : String(format: "£%.2f", value)
    }
}

/// Pure threshold/throttle logic, separated from UserDefaults and
/// UNUserNotificationCenter so it is trivially testable.
enum AlertEvaluator {
    /// How stale a reading can be and still drive an alert. Background runs can
    /// hand us an old cached snapshot; alerting on hours-old data is worse than
    /// staying quiet.
    static let maxReadingAge: TimeInterval = 2 * 60 * 60

    /// Which alerts should fire for this reading. `lastFired` drives the
    /// once-per-calendar-day throttle; `isEnabled` reflects the Settings toggles.
    static func alertsToFire(grid: LiveGrid,
                             now: Date = .now,
                             calendar: Calendar = .current,
                             isEnabled: (GridAlert) -> Bool,
                             lastFired: (GridAlert) -> Date?) -> [GridAlert] {
        // An all-zero grid is the aggregator's "no data" fallback.
        guard grid.demand > 0, now.timeIntervalSince(grid.asOf) < maxReadingAge else { return [] }

        var firing = GridAlert.allCases.filter { alert in
            guard isEnabled(alert), alert.triggers(on: grid) else { return false }
            if let last = lastFired(alert), calendar.isDate(last, inSameDayAs: now) { return false }
            return true
        }
        // Negative price is the more specific of the two low-price alerts.
        if firing.contains(.negativePrice) {
            firing.removeAll { $0 == .lowPrice }
        }
        return firing
    }
}

/// Wires the evaluator to UserDefaults (toggles + last-fired) and
/// UNUserNotificationCenter. Stateless; construct per call.
struct GridAlertCenter {
    private static let log = Logger(
        subsystem: "org.crainiate.national-grid-live", category: "alerts")

    /// Evaluate the reading and post any due notifications. Safe to call from
    /// both the foreground refresh and the background task — the once-a-day
    /// throttle makes double evaluation idempotent.
    func evaluateAndNotify(grid: LiveGrid, now: Date = .now) async {
        let defaults = UserDefaults.standard
        let alerts = AlertEvaluator.alertsToFire(
            grid: grid,
            now: now,
            isEnabled: { defaults.bool(forKey: $0.settingsKey) },
            lastFired: { defaults.object(forKey: $0.lastFiredKey) as? Date })
        guard !alerts.isEmpty else {
            Self.log.debug("no alerts due (demand \(grid.demand, format: .fixed(precision: 1)), price \(grid.price, format: .fixed(precision: 2)), emissions \(grid.emissions, format: .fixed(precision: 0)))")
            return
        }

        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else {
            // Don't record last-fired: if the user grants permission later
            // today, that day's alert can still go out.
            Self.log.info("alerts due but notifications not authorized: \(alerts.map(\.rawValue).joined(separator: ", "))")
            return
        }

        for alert in alerts {
            let request = UNNotificationRequest(
                identifier: alert.notificationIdentifier,
                content: alert.content(for: grid),
                trigger: nil)   // deliver immediately
            do {
                try await center.add(request)
                defaults.set(now, forKey: alert.lastFiredKey)
                Self.log.info("fired \(alert.rawValue)")
            } catch {
                Self.log.warning("failed to post \(alert.rawValue): \(error.localizedDescription)")
            }
        }
    }

    /// Ask for permission (first toggle-on in Settings → Notifications).
    func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])) ?? false
        Self.log.info("authorization request -> \(granted ? "granted" : "denied")")
        return granted
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }
}

/// Shows alert banners while the app is foregrounded. Without this, alerts
/// evaluated during a foreground refresh are silently discarded — while still
/// consuming the daily throttle.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
