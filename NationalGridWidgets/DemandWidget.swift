//
//  DemandWidget.swift
//  NationalGridWidgets
//
//  Lock Screen widget: Demand = Generation + Transfers.
//  Uses the same 1dp-rounded equation values as the in-app StatusBarView
//  (PeriodAverages.equation*) so the figures match the app and grid.iamkate.com.
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
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
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

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: -2) {
                    Image(systemName: "bolt.fill").font(.system(size: 11))
                    Text(WidgetFormat.gw(avg.equationDemand))
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .minimumScaleFactor(0.7)
                    Text("GW").font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }

        default: // .accessoryRectangular
            rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Demand", systemImage: "bolt.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(WidgetFormat.gw(avg.equationDemand))
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("GW").font(.caption2).foregroundStyle(.secondary)
            }
            Text(equationLine)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .widgetAccentable()
    }

    /// "Gen 28.5 + Trans 4.0" — operator flips to "−" for net exports,
    /// matching StatusBarView / Equation.php.
    private var equationLine: String {
        let op = avg.equationTransfers < 0 ? "−" : "+"
        return "Gen \(WidgetFormat.gw(avg.equationGeneration)) \(op) Trans \(WidgetFormat.gw(abs(avg.equationTransfers)))"
    }
}
