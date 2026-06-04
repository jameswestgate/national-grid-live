//
//  GridTimelineProvider.swift
//  NationalGridWidgets
//
//  One timeline provider feeds both Lock Screen widgets. Each refresh does a
//  light, current-only fetch (LiveDataAggregator.fetchCurrentOnly) so the
//  widget stays fresh while the app is closed, without the memory cost of the
//  app's full day/week fetch. The last good value is cached in the widget's own
//  container as an offline fallback.
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
    /// Tiny fallback cache (one composed LiveGrid) in the widget's own
    /// container — distinct from the app's `live-store.json`.
    private let fallback = try? JSONCache<LiveGrid>(filename: "widget-current.json")

    func placeholder(in context: Context) -> GridEntry {
        GridEntry(date: .now, grid: WidgetSampleData.grid, isPlaceholder: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (GridEntry) -> Void) {
        // Gallery preview: no network — show cached or sample immediately.
        let grid = fallback?.read() ?? WidgetSampleData.grid
        completion(GridEntry(date: .now, grid: grid))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GridEntry>) -> Void) {
        Task {
            let now = Date()
            let grid = await fetchCurrent() ?? fallback?.read() ?? WidgetSampleData.grid
            let entry = GridEntry(date: now, grid: grid)
            // Ask WidgetKit to refresh ~20 min out (it schedules within its own
            // budget). Live grid values move slowly, so this is plenty.
            let next = now.addingTimeInterval(20 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchCurrent() async -> LiveGrid? {
        do {
            let grid = try await LiveDataAggregator().fetchCurrentOnly()
            // Treat an all-zero compose (no FUELINST yet) as "no data".
            guard grid.demand != 0 || grid.generation != 0 else { return nil }
            fallback?.write(grid)
            return grid
        } catch {
            return nil
        }
    }
}

// MARK: - Shared formatting

enum WidgetFormat {
    /// GW to one decimal place, e.g. "32.4".
    static func gw(_ value: Double) -> String { String(format: "%.1f", value) }
    /// A whole-number percentage, e.g. "42%".
    static func pct(_ share: Double) -> String { String(format: "%.0f%%", share * 100) }
}
