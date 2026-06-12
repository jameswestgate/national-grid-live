//
//  HomeInterconnectorsWidget.swift
//  NationalGridWidgets
//
//  Home Screen widget: live interconnector flows as the app's diverging bar —
//  exports left, imports right of a centre gap — with a compact legend of all
//  six countries (signed values; negative = exporting). Full colour, same
//  swatches as the app.
//

import WidgetKit
import SwiftUI

struct HomeInterconnectorsWidget: Widget {
    let kind = "HomeInterconnectorsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GridTimelineProvider()) { entry in
            HomeInterconnectorsWidgetView(grid: entry.grid)
                .containerBackground(for: .widget) { Palette.contentBackground }
        }
        .configurationDisplayName("Interconnectors")
        .description("Live electricity imports and exports with Europe.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeInterconnectorsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let grid: LiveGrid

    /// All six countries in declaration order — a stable layout users learn.
    private var flows: [(interconnector: Interconnector, gw: Double)] {
        Interconnector.allCases.map { ($0, grid.interconnectors[$0] ?? 0) }
    }

    private var net: Double { grid.interconnectorsTotal }

    private var barFlows: [(color: Color, gw: Double)] {
        flows.compactMap { abs($0.gw) >= 0.05 ? ($0.interconnector.swatch, $0.gw) : nil }
    }

    private func legendItems(_ items: [(interconnector: Interconnector, gw: Double)]) -> [WidgetLegendItem] {
        items.map { item in
            WidgetLegendItem(
                id: item.interconnector.rawValue,
                color: item.interconnector.swatch,
                name: item.interconnector.displayName,
                value: WidgetFormat.source(item.gw),
                dimmed: abs(item.gw) < 0.05)
        }
    }

    var body: some View {
        switch family {
        case .systemSmall: small
        default: medium
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("Interconnectors")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                netValue(size: 17)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            WidgetDivergingBar(flows: barFlows, height: 16)

            // No exports/imports axis labels — direction is implied by the
            // diverging bar and the signed legend values, as in the app.
            WidgetLegend(items: legendItems(flows))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Interconnectors")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            netValue(size: 15)

            WidgetDivergingBar(flows: barFlows, height: 12)

            // Top four by magnitude; signed legend values carry direction.
            WidgetLegend(items: legendItems(Array(
                flows.sorted { abs($0.gw) > abs($1.gw) }.prefix(4))))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // Direction word BEFORE the number so the value + "GW" sit at the trailing
    // edge — lining up with the Generation widget's header when the two medium
    // widgets are stacked on the Home Screen.
    private func netValue(size: CGFloat) -> Text {
        Text("\(Text(net >= 0 ? "import " : "export ").font(.caption2).foregroundStyle(.secondary))\(Text(WidgetFormat.gw(abs(net))).font(.system(size: size, weight: .semibold, design: .rounded)))\(Text(" GW").font(.caption2).foregroundStyle(.secondary))")
    }
}

#Preview("Medium", as: .systemMedium) {
    HomeInterconnectorsWidget()
} timeline: {
    GridEntry(date: .now, grid: WidgetSampleData.grid)
}

#Preview("Small", as: .systemSmall) {
    HomeInterconnectorsWidget()
} timeline: {
    GridEntry(date: .now, grid: WidgetSampleData.grid)
}
