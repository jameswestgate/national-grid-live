import SwiftUI

/// The generation mix as a single expandable card. A header row, then an
/// optional visualisation (bar / donut / none — chosen in Settings), then the
/// top-level groups (Fossil / Renewables / Other Sources) which disclose their
/// constituent sources on tap. Percentages are share-of-demand throughout, so
/// the three groups sum to the headline "% of demand".
struct GenerationCard: View {
    let generation: Double
    let demand: Double
    let fuels: [FuelType: Double]
    /// Asks the enclosing scroll view to bring a row id into view (see `rowID`).
    /// Optional so the card still works (just expands) without a `ScrollViewReader`.
    var onScrollTo: ((String) -> Void)? = nil

    @AppStorage(AppSettings.generationVisualisationKey) private var visualisation: GenerationVisualisation = .bar

    // Renewables starts expanded (the largest, most-watched group); the user
    // discloses or collapses the rest.
    @State private var expanded: Set<String> = ["Renewables"]

    private struct Group: Identifiable {
        let style: CategoryStyle
        let category: FuelCategory
        let name: String
        let members: [FuelType]
        var id: String { name }
    }

    private let groups: [Group] = [
        Group(style: .fossil,    category: .fossil,    name: "Fossil Fuels",  members: [.gas, .coal]),
        Group(style: .renewable, category: .renewable, name: "Renewables",    members: [.wind, .solar, .hydro]),
        Group(style: .other,     category: .other,     name: "Other Sources", members: [.nuclear, .biomass])
    ]

    private func groupRowID(_ id: String) -> String { "gen-group-\(id)" }
    private func fuelRowID(_ fuel: FuelType) -> String { "gen-fuel-\(fuel.rawValue)" }

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

                visualisationGraphic

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

    /// The chosen visualisation between the header and the groups. Bar and donut
    /// share the same ~22pt top/bottom breathing room; "none" renders nothing.
    @ViewBuilder
    private var visualisationGraphic: some View {
        switch visualisation {
        case .bar:
            GenerationBars(fuels: fuels) { select($0) }
                .padding(.horizontal, 16)
                .padding(.top, 8)      // + the header's 14pt below ≈ 22pt above
                .padding(.bottom, 22)
        case .donut:
            GenerationDonut(fuels: fuels) { select($0) }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 22)
        case .hidden:
            EmptyView()
        }
    }

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
                            percent: share(fuels[fuel] ?? 0),
                            reservesChevronSpace: true
                        )
                        .id(fuelRowID(fuel))
                    }
                }
                // Asymmetric inset: keep the leading indent (hierarchy cue) but let
                // the trailing edge reach the same line as the group header, so the
                // GW/% column aligns with the header row above.
                .padding(.leading, 14)
                .padding(.trailing, 4)
                .padding(.vertical, 14)
                .background(Palette.tableStripe, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
        }
        .id(groupRowID(group.id))
    }

    private func share(_ v: Double) -> Double { demand > 0 ? v / demand : 0 }

    /// Bar segment tapped → reveal the matching group and scroll its detail into
    /// view. Category-bar taps target the group header; fuel-bar taps target that
    /// fuel's row.
    private func select(_ selection: GenerationSelection) {
        let group: Group
        let scrollID: String
        switch selection {
        case .category(let category):
            guard let g = groups.first(where: { $0.category == category }) else { return }
            group = g
            scrollID = groupRowID(g.id)
        case .fuel(let fuel):
            guard let g = groups.first(where: { $0.members.contains(fuel) }) else { return }
            group = g
            scrollID = fuelRowID(fuel)
        }

        withAnimation(.snappy(duration: 0.26)) { expanded.insert(group.id) }
        // Defer the scroll a runloop so the freshly-revealed rows are laid out
        // and their ids are resolvable by the ScrollViewReader.
        DispatchQueue.main.async {
            withAnimation(.snappy(duration: 0.3)) { onScrollTo?(scrollID) }
        }
    }
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
