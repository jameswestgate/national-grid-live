//
//  LiveMinimalWidget.swift
//  NationalGridWidgets
//
//  Lock Screen widget: a title-less summary. The hero line carries demand
//  (rounded to a whole GW), the market price and carbon intensity (as plain
//  grams); the row beneath shows the four largest individual sources by absolute
//  flow — across generation fuels, interconnectors and storage — but never the
//  generation total. Mirrors the Android "Live Minimal" home-screen widget;
//  Lock Screen accessories render monochrome, so it leans on SF Symbols + numbers
//  rather than the app's fuel colours (the Android version keeps the colours).
//

import WidgetKit
import SwiftUI

struct LiveMinimalWidget: Widget {
    let kind = "LiveMinimalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GridTimelineProvider()) { entry in
            LiveMinimalWidgetView(grid: entry.grid)
                .containerBackground(Color.clear, for: .widget)
        }
        .configurationDisplayName("Live Minimal")
        .description("Demand, price and carbon with the top live sources.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct LiveMinimalWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let grid: LiveGrid

    private var avg: PeriodAverages { grid.asAverages }

    /// One source in the breakdown row.
    private struct Source: Identifiable {
        let id: String
        let symbol: String
        let gw: Double
    }

    /// The four largest sources by |flow|, across generation fuels,
    /// interconnectors and storage — the generation total is deliberately
    /// excluded (same pool as the Android Live Minimal widget).
    private var topSources: [Source] {
        var items: [Source] = []
        for (fuel, gw) in grid.fuels where fuel != .pumped {
            items.append(Source(id: "f-\(fuel.rawValue)", symbol: fuel.systemImage, gw: gw))
        }
        for (ic, gw) in grid.interconnectors {
            items.append(Source(id: "i-\(ic.rawValue)", symbol: ic.systemImage, gw: gw))
        }
        if let pumped = grid.fuels[.pumped] {
            items.append(Source(id: "pumped", symbol: "minus.plus.batteryblock.fill", gw: pumped))
        }
        return Array(items.sorted { abs($0.gw) > abs($1.gw) }.prefix(4))
    }

    var body: some View {
        switch family {
        case .accessoryInline:
            // One line above the clock: demand and price.
            Label(
                "\(WidgetFormat.whole(avg.equationDemand)) GW  £\(WidgetFormat.whole(grid.price))",
                systemImage: "bolt.fill"
            )

        default: // .accessoryRectangular
            rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Hero: demand · price · carbon. Units (GW, £, g) are small + grey
            // and sit tight against their numbers (no gaps); the three stats are
            // separated by a little leading padding.
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                // Demand + unit, no gap.
                Text(WidgetFormat.whole(avg.equationDemand))
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("GW").font(.caption2).foregroundStyle(.secondary)

                // Price: "£" small + grey like the unit, then the number.
                Text("£").font(.caption2).foregroundStyle(.secondary)
                    .padding(.leading, 7)
                Text(WidgetFormat.whole(grid.price))
                    .font(.callout.weight(.medium))

                // Carbon: number then "g" small + grey, no gap.
                Text(WidgetFormat.whole(grid.emissions))
                    .font(.callout.weight(.medium))
                    .padding(.leading, 7)
                Text("g").font(.caption2).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            // Breakdown: the four largest sources (icon + GW). Spacing and icons
            // are kept tight so the numbers get the most width and read at full
            // size without scaling down.
            HStack(spacing: 3) {
                ForEach(topSources) { source in
                    HStack(spacing: 1) {
                        Image(systemName: source.symbol)
                            .font(.system(size: 9))
                            .frame(width: 11)
                        Text(WidgetFormat.gw(source.gw))
                            .font(.caption2.weight(.semibold))
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
        .padding(.bottom, 4)
        .widgetAccentable()
    }
}
