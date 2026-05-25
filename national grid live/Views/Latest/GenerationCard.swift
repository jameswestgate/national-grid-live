import SwiftUI

struct GenerationCard: View {
    let generation: Double
    let demand: Double
    let fuels: [FuelType: Double]
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Card {
            if sizeClass == .regular {
                ipadLayout
                    .padding(16)
            } else {
                iphoneLayout
                    .padding(16)
            }
        }
    }

    private var iphoneLayout: some View {
        GenerationDonut(
            generation: generation,
            demand: demand,
            fuels: fuels,
            size: 280
        )
        .frame(maxWidth: .infinity)
    }

    private var ipadLayout: some View {
        HStack(alignment: .center, spacing: 16) {
            GenerationDonut(
                generation: generation,
                demand: demand,
                fuels: fuels,
                size: 180
            )
            legend
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 14) {
            legendRow(style: .fossil, name: "Fossil Fuels")
            legendRow(style: .renewable, name: "Renewables")
            legendRow(style: .other, name: "Other Sources")
        }
    }

    private func legendRow(style: CategoryStyle, name: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(style.tint)
                .frame(width: 10, height: 10)
            Text(name)
                .font(.callout)
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

#Preview {
    GenerationCard(
        generation: LiveGrid.sample.generation,
        demand: LiveGrid.sample.demand,
        fuels: LiveGrid.sample.fuels
    )
    .padding()
    .background(Palette.pageBackground)
}
