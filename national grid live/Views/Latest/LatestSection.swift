import SwiftUI

struct LatestSection: View {
    let live: LiveGrid
    @State private var width: CGFloat = 0

    var body: some View {
        layoutFor(width: width)
            .frame(maxWidth: .infinity)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: WidthKey.self, value: proxy.size.width)
                }
            )
            .onPreferenceChange(WidthKey.self) { newWidth in
                width = newWidth
            }
    }

    private struct WidthKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    @ViewBuilder
    private func layoutFor(width: CGFloat) -> some View {
        let isWide = width >= 780

        VStack(spacing: 12) {
            SectionHeader(title: "Generation", topSpacing: 0)

            if isWide {
                HStack(alignment: .top, spacing: 12) {
                    generationCard.frame(maxWidth: .infinity)
                    VStack(spacing: 12) {
                        fossilsCard
                        renewablesCard
                        othersCard
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                generationCard
                fossilsCard
                renewablesCard
                othersCard
            }

            SectionHeader(title: "Interconnectors")
            interconnectorsCard

            SectionHeader(title: "Storage")
            storageCard

            footnote
        }
    }

    private var generationCard: some View {
        GenerationCard(live: live)
    }

    private var fossilsCard: some View {
        let total = live.categoryTotal(.fossil)
        return CategoryCard(
            style: .fossil,
            name: "Fossil Fuels",
            totalGW: total,
            percentOfDemand: live.share(total),
            entries: entries(for: [.coal, .gas])
        )
    }

    private var renewablesCard: some View {
        let total = live.categoryTotal(.renewable)
        return CategoryCard(
            style: .renewable,
            name: "Renewables",
            totalGW: total,
            percentOfDemand: live.share(total),
            entries: entries(for: [.solar, .wind, .hydro])
        )
    }

    private var othersCard: some View {
        let total = live.categoryTotal(.other)
        return CategoryCard(
            style: .other,
            name: "Other Sources",
            totalGW: total,
            percentOfDemand: live.share(total),
            entries: entries(for: [.nuclear, .biomass])
        )
    }

    private var interconnectorsCard: some View {
        let total = live.interconnectorsTotal
        return CategoryCard(
            style: .interconnectors,
            name: nil,
            totalGW: total,
            percentOfDemand: live.share(total),
            entries: Interconnector.allCases
                .sorted { $0.displayName < $1.displayName }
                .map { ic in
                    let gw = live.interconnectors[ic] ?? 0
                    return SourceEntry(
                        id: ic.rawValue,
                        label: ic.displayName,
                        color: ic.swatch,
                        valueGW: gw,
                        percentOfDemand: live.share(gw)
                    )
                }
        )
    }

    private var storageCard: some View {
        let pumped = live.fuels[.pumped] ?? 0
        return CategoryCard(
            style: .storage,
            name: nil,
            totalGW: pumped,
            percentOfDemand: live.share(pumped),
            entries: [
                SourceEntry(
                    id: "pumped",
                    label: "Pumped storage",
                    color: FuelType.pumped.swatch,
                    valueGW: pumped,
                    percentOfDemand: live.share(pumped)
                ),
                SourceEntry(
                    id: "battery",
                    label: "Battery storage",
                    color: Color(red: 0.55, green: 0.40, blue: 0.78),
                    valueGW: nil,
                    percentOfDemand: nil
                )
            ]
        )
    }

    private func entries(for fuels: [FuelType]) -> [SourceEntry] {
        fuels.map { fuel in
            let gw = live.fuels[fuel] ?? 0
            return SourceEntry(
                id: fuel.rawValue,
                label: fuel.displayName,
                color: fuel.swatch,
                valueGW: gw,
                percentOfDemand: live.share(gw)
            )
        }
    }

    private var footnote: some View {
        Text("Note: percentages are relative to demand, so will exceed 100% if power is being exported")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.top, 4)
    }
}

#Preview("iPhone") {
    LatestSection(live: .sample)
        .padding()
        .background(Palette.pageBackground)
}

#Preview("iPad") {
    LatestSection(live: .sample)
        .padding()
        .background(Palette.pageBackground)
}
