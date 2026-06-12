//
//  HomeGenerationWidget.swift
//  NationalGridWidgets
//
//  Home Screen widget: the live generation mix as the app's signature
//  colour-coded bar (category strip over fuel bar at medium; fuel bar only at
//  small) with a compact legend. Unlike the Lock Screen accessories these
//  render in full colour, reading the same Palette swatches as the app.
//

import WidgetKit
import SwiftUI

struct HomeGenerationWidget: Widget {
    let kind = "HomeGenerationWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GridTimelineProvider()) { entry in
            HomeGenerationWidgetView(grid: entry.grid)
                .containerBackground(for: .widget) { Palette.contentBackground }
        }
        .configurationDisplayName("Generation mix")
        .description("The live generation mix, fuel by fuel, as a colour-coded bar.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HomeGenerationWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let grid: LiveGrid

    private var avg: PeriodAverages { grid.asAverages }

    /// Same ordering as the app's GenerationBars: categories fossil →
    /// renewable → other, fuels in declaration order within each category.
    /// Pumped storage is `.storage`, so it is excluded automatically.
    private static let categoryOrder: [FuelCategory] = [.fossil, .renewable, .other]

    private var activeFuels: [(fuel: FuelType, gw: Double)] {
        Self.categoryOrder.flatMap { category in
            FuelType.allCases
                .filter { $0.category == category }
                .compactMap { fuel -> (FuelType, Double)? in
                    let gw = grid.fuels[fuel] ?? 0
                    return gw > 0.05 ? (fuel, gw) : nil
                }
        }
    }

    private var categorySegments: [(color: Color, value: Double)] {
        Self.categoryOrder.compactMap { category in
            let total = grid.categoryTotal(category)
            return total > 0 ? (category.bannerColor, total) : nil
        }
    }

    private var fuelSegments: [(color: Color, value: Double)] {
        activeFuels.map { ($0.fuel.swatch, $0.gw) }
    }

    private func legendItems(_ fuels: [(fuel: FuelType, gw: Double)]) -> [WidgetLegendItem] {
        fuels.map { item in
            WidgetLegendItem(
                id: item.fuel.rawValue,
                color: item.fuel.swatch,
                name: item.fuel == .hydro ? "Hydro" : item.fuel.displayName,
                value: WidgetFormat.source(item.gw))
        }
    }

    var body: some View {
        switch family {
        case .systemSmall: small
        default: medium
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 7) {
            header(valueSize: 17)
            VStack(spacing: 3) {
                WidgetSegmentBar(segments: categorySegments, height: 6, corner: 3)
                WidgetSegmentBar(segments: fuelSegments, height: 16)
            }
            WidgetLegend(items: legendItems(activeFuels))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // Mirrors the Interconnectors small layout: title above, value beneath —
    // a single header row truncates the title at this width.
    private var small: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Generation")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(Text(WidgetFormat.gw(avg.equationGeneration)).font(.system(size: 15, weight: .semibold, design: .rounded)))\(Text(" GW").font(.caption2).foregroundStyle(.secondary))")
            WidgetSegmentBar(segments: fuelSegments, height: 12)
            WidgetLegend(items: legendItems(Array(
                activeFuels.sorted { $0.gw > $1.gw }.prefix(4))))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func header(valueSize: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Generation")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            Text("\(Text(WidgetFormat.gw(avg.equationGeneration)).font(.system(size: valueSize, weight: .semibold, design: .rounded)))\(Text(" GW").font(.caption2).foregroundStyle(.secondary))")
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

#Preview("Medium", as: .systemMedium) {
    HomeGenerationWidget()
} timeline: {
    GridEntry(date: .now, grid: WidgetSampleData.grid)
}

#Preview("Small", as: .systemSmall) {
    HomeGenerationWidget()
} timeline: {
    GridEntry(date: .now, grid: WidgetSampleData.grid)
}
