import SwiftUI

struct PeriodBreakdownView: View {
    let averages: PeriodAverages

    private static let byTypeOrder: [FuelCategory] = [.fossil, .renewable, .other]
    private static let bySourceOrder: [FuelType] = [.coal, .gas, .solar, .wind, .hydro, .nuclear, .biomass]

    var body: some View {
        VStack(spacing: 24) {
            section(title: "Generation by type") {
                ForEach(Self.byTypeOrder, id: \.self) { category in
                    let total = averages.categoryTotal(category)
                    SourceRow(
                        label: category.displayName.capitalized,
                        swatch: category.bannerColor,
                        valueGW: total,
                        percent: averages.share(total)
                    )
                }
            }

            section(title: "Generation by source") {
                ForEach(Self.bySourceOrder, id: \.self) { fuel in
                    let gw = averages.fuels[fuel] ?? 0
                    SourceRow(
                        label: fuel.displayName,
                        swatch: fuel.swatch,
                        valueGW: gw,
                        percent: averages.share(gw)
                    )
                }
            }

            section(title: "Interconnectors") {
                ForEach(Interconnector.allCases, id: \.self) { ic in
                    let gw = averages.interconnectors[ic] ?? 0
                    SourceRow(
                        label: ic.displayName,
                        swatch: ic.swatch,
                        valueGW: gw,
                        percent: averages.share(gw),
                        outlinedSwatch: true
                    )
                }
            }

            section(title: "Storage") {
                let pumped = averages.fuels[.pumped] ?? 0
                SourceRow(
                    label: "Pumped storage",
                    swatch: FuelType.pumped.swatch,
                    valueGW: pumped,
                    percent: averages.share(pumped),
                    outlinedSwatch: true
                )
                SourceRow(
                    label: "Battery storage",
                    swatch: Color(red: 0.55, green: 0.40, blue: 0.78),
                    valueGW: nil,
                    percent: nil,
                    outlinedSwatch: true
                )
            }
        }
    }

    @ViewBuilder
    private func section<Rows: View>(title: String, @ViewBuilder rows: () -> Rows) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.appSerif(.headline, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
            VStack(spacing: 0) {
                rows()
            }
        }
    }
}

#Preview {
    PeriodBreakdownView(averages: .from(LiveData.sample.day))
        .padding()
        .background(Palette.contentBackground)
        .preferredColorScheme(.dark)
}
