import SwiftUI

/// Renders the Generation / Interconnectors / Storage sections.
/// Source-agnostic — takes a `PeriodAverages` so the same view powers the Live
/// snapshot and the historic period averages.
struct LatestSection: View {
    let stats: PeriodAverages
    /// Caption rendered directly under the generation card, e.g.
    /// ("Generation time", "1:45pm") on Live or ("Period", "Past day") on Historic.
    var caption: (label: String, value: String)? = nil
    var captionInfo: String? = nil
    /// Forwarded to the generation card so a donut tap can scroll a row into view.
    var onScrollTo: ((String) -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            GenerationCard(
                generation: stats.generation,
                demand: stats.demand,
                fuels: stats.fuels,
                onScrollTo: onScrollTo
            )

            if let caption {
                GenerationCaption(label: caption.label, value: caption.value, info: captionInfo)
            }

            interconnectorsCard
            storageCard
        }
    }

    private var interconnectorsCard: some View {
        let total = stats.interconnectorsTotal
        return SourceListCard(
            title: "Interconnectors",
            totalGW: total,
            caption: String(format: "%.1f%% of demand", stats.share(total) * 100),
            items: Interconnector.allCases
                .sorted { $0.displayName < $1.displayName }
                .map { ic in
                    let gw = stats.interconnectors[ic] ?? 0
                    return SourceListItem(
                        id: ic.rawValue,
                        icon: ic.systemImage,
                        tint: ic.swatch,
                        name: ic.displayName,
                        gw: gw,
                        percent: stats.share(gw)
                    )
                }
        )
    }

    private var storageCard: some View {
        let pumped = stats.fuels[.pumped] ?? 0
        return SourceListCard(
            title: "Storage",
            totalGW: pumped,
            caption: String(format: "%.1f%% of demand", stats.share(pumped) * 100),
            items: [
                SourceListItem(
                    id: "pumped",
                    icon: FuelType.pumped.systemImage,
                    tint: FuelType.pumped.swatch,
                    name: "Pumped storage",
                    gw: pumped,
                    percent: stats.share(pumped)
                ),
                SourceListItem(
                    id: "battery",
                    icon: "minus.plus.batteryblock.fill",
                    tint: Color(.systemPurple),
                    name: "Battery storage",
                    gw: nil,
                    percent: nil
                )
            ]
        )
    }
}

#Preview("iPhone") {
    ScrollView {
        LatestSection(stats: LiveGrid.sample.asAverages)
            .padding()
    }
    .background(Palette.pageBackground)
}
