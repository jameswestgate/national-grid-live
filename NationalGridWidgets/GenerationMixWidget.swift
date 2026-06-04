//
//  GenerationMixWidget.swift
//  NationalGridWidgets
//
//  Lock Screen widget: the live generation mix — the largest contributing
//  fuels (icon + GW) plus the current renewable share. Lock Screen accessory
//  widgets render monochrome, so this relies on SF Symbols + numbers rather
//  than the app's fuel colours.
//

import WidgetKit
import SwiftUI

struct GenerationMixWidget: Widget {
    let kind = "GenerationMixWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GridTimelineProvider()) { entry in
            GenerationMixWidgetView(grid: entry.grid)
                .containerBackground(Color.clear, for: .widget)
        }
        .configurationDisplayName("Generation mix")
        .description("The live generation mix and renewable share.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct GenerationMixWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let grid: LiveGrid

    /// Largest contributing fuels, ignoring pumped storage (a transfer, not
    /// generation) and anything that rounds to zero.
    private var topFuels: [(fuel: FuelType, gw: Double)] {
        grid.fuels
            .filter { $0.key != .pumped && $0.value >= 0.05 }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { (fuel: $0.key, gw: $0.value) }
    }

    private var renewableShare: Double { grid.share(grid.categoryTotal(.renewable)) }

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("\(WidgetFormat.pct(renewableShare)) renewable", systemImage: "leaf.fill")

        case .accessoryCircular:
            Gauge(value: min(max(renewableShare, 0), 1)) {
                Image(systemName: "leaf.fill")
            } currentValueLabel: {
                Text(WidgetFormat.pct(renewableShare))
                    .minimumScaleFactor(0.7)
            }
            .gaugeStyle(.accessoryCircular)

        default: // .accessoryRectangular
            rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Renewable", systemImage: "leaf.fill")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(WidgetFormat.pct(renewableShare))
                    .font(.system(.title, design: .rounded).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("of demand").font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                ForEach(topFuels, id: \.fuel) { item in
                    HStack(spacing: 3) {
                        Image(systemName: item.fuel.systemImage)
                            .font(.system(size: 11))
                            .frame(width: 14)
                        Text(WidgetFormat.gw(item.gw))
                            .font(.caption2.weight(.semibold))
                    }
                }
            }
        }
        .widgetAccentable()
    }
}
