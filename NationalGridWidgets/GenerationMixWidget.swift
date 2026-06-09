//
//  GenerationMixWidget.swift
//  NationalGridWidgets
//
//  Lock Screen widget: total generation (hero) with the top-3 contributing
//  fuels (icon + GW) in the row beneath. Lock Screen accessory widgets render
//  monochrome, so this relies on SF Symbols + numbers rather than the app's
//  fuel colours.
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
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct GenerationMixWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let grid: LiveGrid

    private var avg: PeriodAverages { grid.asAverages }

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

        default: // .accessoryRectangular
            rectangular
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Generation")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(WidgetFormat.gw(avg.equationGeneration))
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("GW").font(.caption2).foregroundStyle(.secondary)
                // Carbon intensity (g/kWh), whole number as in StatusBarView.
                // A small leading gap separates it from the generation value;
                // kept tight so "g/kWh" stays on the line.
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(WidgetFormat.whole(grid.emissions))
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("g/kWh").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.leading, 4)
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
            .padding(.top, 2)
        }
        .padding(.bottom, 6)
        .widgetAccentable()
    }
}
