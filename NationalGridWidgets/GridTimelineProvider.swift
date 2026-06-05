//
//  GridTimelineProvider.swift
//  NationalGridWidgets
//
//  One timeline provider feeds both Lock Screen widgets. It prefers the App
//  Group snapshot the app publishes on each refresh (so the widget's numbers
//  exactly match the app) and only does its own light current-only fetch
//  (LiveDataAggregator.fetchCurrentOnly) when the app hasn't refreshed recently
//  — keeping it fresh while the app is closed, without the memory cost of the
//  app's full day/week fetch.
//

import WidgetKit
import Foundation

struct GridEntry: TimelineEntry {
    let date: Date
    let grid: LiveGrid
    /// True for the gallery placeholder so views can redact convincingly.
    var isPlaceholder: Bool = false
}

struct GridTimelineProvider: TimelineProvider {
    /// Snapshot the APP publishes on each refresh, in the shared App Group
    /// container. Reading it (rather than fetching our own) is what keeps the
    /// widget's numbers identical to the app.
    private let shared = try? JSONCache<LiveGrid>(
        filename: AppGroup.snapshotFilename, appGroup: AppGroup.identifier)

    /// Mirror the app's reading only while it's essentially live — just over the
    /// app's 5-min refresh, so the widget matches the app whenever it's open and
    /// otherwise fetches its own fresh data.
    private let freshnessWindow: TimeInterval = 6 * 60

    func placeholder(in context: Context) -> GridEntry {
        GridEntry(date: .now, grid: WidgetSampleData.grid, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (GridEntry) -> Void) {
        // Gallery preview: no network — show the shared snapshot or sample.
        let grid = shared?.read() ?? WidgetSampleData.grid
        completion(GridEntry(date: .now, grid: grid))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GridEntry>) -> Void) {
        Task {
            let now = Date()
            let grid = await currentGrid(now: now)
            let entry = GridEntry(date: now, grid: grid)
            // Ask WidgetKit to refresh ~20 min out (it schedules within its own
            // budget). Live grid values move slowly, so this is plenty.
            let next = now.addingTimeInterval(20 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    /// Prefer the app's shared reading so the widget matches the app exactly;
    /// fall back to our own light fetch only when the app hasn't refreshed
    /// recently (e.g. it's been closed a while).
    private func currentGrid(now: Date) async -> LiveGrid {
        let appSnapshot = shared?.read()
        if let s = appSnapshot, now.timeIntervalSince(s.asOf) < freshnessWindow {
            return s
        }
        if let fetched = try? await LiveDataAggregator().fetchCurrentOnly(),
           fetched.demand != 0 || fetched.generation != 0 {
            shared?.write(fetched)   // keep the shared snapshot warm while the app is closed
            return fetched
        }
        return appSnapshot ?? WidgetSampleData.grid
    }
}

// MARK: - Shared formatting

enum WidgetFormat {
    /// GW to one decimal place, e.g. "32.4".
    static func gw(_ value: Double) -> String { String(format: "%.1f", value) }
    /// A whole number with no decimal, e.g. "108" — for price (£/MWh) and
    /// emissions (g/kWh).
    static func whole(_ value: Double) -> String { String(format: "%.0f", value) }
    /// A whole-number percentage, e.g. "42%".
    static func pct(_ share: Double) -> String { String(format: "%.0f%%", share * 100) }
}
