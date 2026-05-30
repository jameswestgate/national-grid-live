import SwiftUI

/// The generation mix as a single expandable card — replaces the donut.
/// Top-level groups (Fossil / Renewables / Other Sources) disclose their
/// constituent sources on tap. Percentages are share-of-demand throughout, so
/// the three groups sum to the headline "% of demand".
struct GenerationCard: View {
    let generation: Double
    let demand: Double
    let fuels: [FuelType: Double]

    // All groups start collapsed; the user discloses the ones they care about.
    @State private var expanded: Set<String> = []

    private struct Group: Identifiable {
        let style: CategoryStyle
        let name: String
        let members: [FuelType]
        var id: String { name }
    }

    private let groups: [Group] = [
        Group(style: .fossil,    name: "Fossil Fuels",  members: [.gas, .coal]),
        Group(style: .renewable, name: "Renewables",    members: [.wind, .solar, .hydro]),
        Group(style: .other,     name: "Other Sources", members: [.nuclear, .biomass])
    ]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardSectionHeader(
                    title: "Generation",
                    valueGW: generation,
                    caption: String(format: "%.1f%% of demand", shareOfDemand * 100)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 14)

                ForEach(groups) { group in
                    Divider().padding(.leading, 16)
                    groupSection(group)
                }

                Divider().padding(.leading, 16)
                Text("Percentages show each source's share of total demand.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
        }
    }

    private var shareOfDemand: Double { demand > 0 ? generation / demand : 0 }

    @ViewBuilder
    private func groupSection(_ group: Group) -> some View {
        let total = group.members.reduce(0.0) { $0 + (fuels[$1] ?? 0) }
        let isExpanded = expanded.contains(group.id)

        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.26)) {
                    if isExpanded { expanded.remove(group.id) } else { expanded.insert(group.id) }
                }
            } label: {
                SourceRow(
                    icon: group.style.systemImage,
                    tint: group.style.tint,
                    name: group.name,
                    gw: total,
                    percent: share(total),
                    chevron: isExpanded ? .down : .right,
                    emphasised: true
                )
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 16) {
                    ForEach(group.members, id: \.self) { fuel in
                        SourceRow(
                            icon: fuel.systemImage,
                            tint: fuel.swatch,
                            name: fuel.displayName,
                            gw: fuels[fuel] ?? 0,
                            percent: share(fuels[fuel] ?? 0)
                        )
                    }
                }
                .padding(14)
                .background(Palette.tableStripe, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
    }

    private func share(_ v: Double) -> Double { demand > 0 ? v / demand : 0 }
}

#Preview {
    ScrollView {
        GenerationCard(
            generation: LiveGrid.sample.generation,
            demand: LiveGrid.sample.demand,
            fuels: LiveGrid.sample.fuels
        )
        .padding()
    }
    .background(Palette.pageBackground)
}
