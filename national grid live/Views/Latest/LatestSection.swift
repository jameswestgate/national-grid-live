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
        switch LayoutKind.pick(width: width) {
        case .single:
            VStack(spacing: 16) {
                generationCard
                fossilsCard
                renewablesCard
                othersCard
                interconnectorsCard
                storageCard
            }
        case .double:
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    generationCard.frame(maxWidth: .infinity)
                    VStack(spacing: 16) {
                        fossilsCard
                        renewablesCard
                        othersCard
                    }
                    .frame(maxWidth: .infinity)
                }
                HStack(alignment: .top, spacing: 16) {
                    interconnectorsCard.frame(maxWidth: .infinity)
                    storageCard.frame(maxWidth: .infinity)
                }
            }
        case .triple:
            HStack(alignment: .top, spacing: 16) {
                generationCard.frame(maxWidth: .infinity)
                VStack(spacing: 16) {
                    fossilsCard
                    renewablesCard
                    othersCard
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 16) {
                    interconnectorsCard
                    storageCard
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    enum LayoutKind {
        case single, double, triple

        static func pick(width: CGFloat) -> LayoutKind {
            switch width {
            case ..<780: .single
            case 780..<1200: .double
            default: .triple
            }
        }
    }

    private var generationCard: some View {
        GenerationCard(live: live)
    }

    private var fossilsCard: some View {
        let total = live.categoryTotal(.fossil)
        return CategoryCard(
            title: FuelCategory.fossil.displayName,
            percent: live.share(total),
            banner: FuelCategory.fossil.bannerColor
        ) {
            ForEach(FuelType.allCases.filter { $0.category == .fossil }, id: \.self) { fuel in
                let gw = live.fuels[fuel] ?? 0
                SourceRow(label: fuel.displayName, swatch: fuel.swatch, valueGW: gw, percent: live.share(gw))
            }
        }
    }

    private var renewablesCard: some View {
        let total = live.categoryTotal(.renewable)
        return CategoryCard(
            title: FuelCategory.renewable.displayName,
            percent: live.share(total),
            banner: FuelCategory.renewable.bannerColor
        ) {
            ForEach([FuelType.solar, .wind, .hydro], id: \.self) { fuel in
                let gw = live.fuels[fuel] ?? 0
                SourceRow(label: fuel.displayName, swatch: fuel.swatch, valueGW: gw, percent: live.share(gw))
            }
        }
    }

    private var othersCard: some View {
        let total = live.categoryTotal(.other)
        return CategoryCard(
            title: FuelCategory.other.displayName,
            percent: live.share(total),
            banner: FuelCategory.other.bannerColor
        ) {
            ForEach([FuelType.nuclear, .biomass], id: \.self) { fuel in
                let gw = live.fuels[fuel] ?? 0
                SourceRow(label: fuel.displayName, swatch: fuel.swatch, valueGW: gw, percent: live.share(gw))
            }
        }
    }

    private var interconnectorsCard: some View {
        let total = live.interconnectorsTotal
        return CategoryCard(
            title: "interconnectors",
            percent: live.share(total),
            banner: FuelCategory.other.bannerColor
        ) {
            ForEach(Interconnector.allCases, id: \.self) { ic in
                let gw = live.interconnectors[ic] ?? 0
                SourceRow(label: ic.displayName, swatch: ic.swatch, valueGW: gw, percent: live.share(gw), outlinedSwatch: true)
            }
        }
    }

    private var storageCard: some View {
        let pumped = live.fuels[.pumped] ?? 0
        return CategoryCard(
            title: FuelCategory.storage.displayName,
            percent: live.share(pumped),
            banner: FuelCategory.storage.bannerColor
        ) {
            SourceRow(label: "Pumped storage", swatch: FuelType.pumped.swatch, valueGW: pumped, percent: live.share(pumped), outlinedSwatch: true)
        }
    }
}

#Preview("iPhone") {
    LatestSection(live: .sample)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}

#Preview("iPad") {
    LatestSection(live: .sample)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
