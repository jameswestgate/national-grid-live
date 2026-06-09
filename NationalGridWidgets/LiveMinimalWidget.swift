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

    /// All three hero numbers share one size (white); their units (GW, £, g)
    /// stay small + grey and sit tight against the number with no gap.
    private var numberFont: Font { .system(size: 20, weight: .semibold, design: .rounded) }

    private var demandStat: Text {
        Text(WidgetFormat.whole(avg.equationDemand)).font(numberFont)
        + Text("GW").font(.caption2).foregroundStyle(.secondary)
    }

    private var priceStat: Text {
        Text("£").font(.caption2).foregroundStyle(.secondary)
        + Text(WidgetFormat.whole(grid.price)).font(numberFont)
    }

    private var carbonStat: Text {
        Text(WidgetFormat.whole(grid.emissions)).font(numberFont)
        + Text("g").font(.caption2).foregroundStyle(.secondary)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 3) {
            // Hero: demand · price · carbon spread across the full width as three
            // equal columns — demand left-aligned, price centred, carbon right-
            // aligned. minimumScaleFactor keeps them on one line whatever the
            // values.
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                demandStat.frame(maxWidth: .infinity, alignment: .leading)
                priceStat.frame(maxWidth: .infinity, alignment: .center)
                carbonStat.frame(maxWidth: .infinity, alignment: .trailing)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            // Breakdown: the four largest sources (icon + GW), spread edge-to-edge
            // so they fill the width. Values keep a decimal below 10 and round to
            // a whole number at 10+ (WidgetFormat.source).
            HStack(spacing: 0) {
                ForEach(Array(topSources.enumerated()), id: \.element.id) { index, source in
                    if index > 0 { Spacer(minLength: 2) }
                    HStack(spacing: 1) {
                        Image(systemName: source.symbol)
                            .font(.system(size: 9))
                            .frame(width: 11)
                        Text(WidgetFormat.source(source.gw))
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
