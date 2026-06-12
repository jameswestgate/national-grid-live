//
//  DemandWidget.swift
//  NationalGridWidgets
//
//  Lock Screen widget: Demand (hero), broken into Generation / Interconnectors
//  / Storage in the row beneath (they sum to demand). The hero uses the same
//  1dp-rounded value as the in-app StatusBarView (PeriodAverages.equationDemand)
//  so it matches the app and grid.iamkate.com.
//

import WidgetKit
import SwiftUI

struct DemandWidget: Widget {
    let kind = "DemandWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GridTimelineProvider()) { entry in
            DemandWidgetView(grid: entry.grid)
                .containerBackground(Color.clear, for: .widget)
        }
        .configurationDisplayName("Demand")
        .description("Demand = Generation + Transfers, live from the grid.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct DemandWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let grid: LiveGrid

    private var avg: PeriodAverages { grid.asAverages }

    var body: some View {
        switch family {
        case .accessoryInline:
            // One line above the clock (system allows one symbol + text).
            Label("Demand \(WidgetFormat.gw(avg.equationDemand)) GW", systemImage: "bolt.fill")

        default: // .accessoryRectangular
            rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Demand")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(WidgetFormat.gw(avg.equationDemand))
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("GW").font(.caption2).foregroundStyle(.secondary)
                // Market price (£/MWh), formatted as in StatusBarView.
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("£").font(.caption2).foregroundStyle(.secondary)
                    Text(WidgetFormat.price(grid.price))
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.leading, 4)
            }
            HStack(spacing: 10) {
                summaryChip("bolt.fill", avg.equationGeneration)
                summaryChip("arrow.left.arrow.right", grid.interconnectorsTotal)
                summaryChip("minus.plus.batteryblock.fill", grid.fuels[.pumped] ?? 0)
            }
            .padding(.top, 2)
        }
        .padding(.bottom, 6)
        .widgetAccentable()
    }

    /// One icon + GW chip in the breakdown row: Generation (bolt),
    /// Interconnectors (arrows), Storage (battery) — together summing to demand.
    private func summaryChip(_ symbol: String, _ gw: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 11))
                .frame(width: 14)
            Text(WidgetFormat.gw(gw))
                .font(.caption2.weight(.semibold))
        }
    }
}
