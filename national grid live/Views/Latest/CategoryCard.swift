import SwiftUI

struct CategoryCard: View {
    let style: CategoryStyle
    /// Inline card title. Pass `nil` for subordinate cards where the section header
    /// above the card already names the section (e.g. Interconnectors, Storage).
    let name: String?
    let totalGW: Double
    let percentOfDemand: Double
    let entries: [SourceEntry]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(16)
                if !entries.isEmpty {
                    Divider().padding(.leading, 16)
                    VStack(spacing: 14) {
                        ForEach(entries) { entry in
                            SourceBarRow(entry: entry, barProgress: progress(for: entry))
                        }
                    }
                    .padding(16)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            IconBadge(style: style)
            if let name {
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(style.isPrimary ? style.tint : Color.primary)
                    Text(gwTotalText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            } else {
                Text(gwTotalText)
                    .font(.headline)
                    .foregroundStyle(Palette.dataText)
                    .monospacedDigit()
            }
            Spacer()
            Text(percentText)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(style.isPrimary ? style.tint : Palette.dataText)
        }
    }

    private var gwTotalText: String {
        let sign = totalGW < 0 ? "−" : ""
        return sign + String(format: "%.2f GW", abs(totalGW))
    }

    private var percentText: String {
        let sign = percentOfDemand < 0 ? "−" : ""
        return sign + String(format: "%.1f%%", abs(percentOfDemand) * 100)
    }

    private func progress(for entry: SourceEntry) -> Double {
        guard let p = entry.percentOfDemand else { return 0 }
        let denom = max(0.0001, abs(percentOfDemand))
        return min(abs(p) / denom, 1.0)
    }
}

private struct IconBadge: View {
    let style: CategoryStyle

    var body: some View {
        ZStack {
            Circle().fill(style.isPrimary ? style.tint : Color(.tertiarySystemFill))
            Image(systemName: style.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(style.isPrimary ? Color.white : Palette.dataText)
        }
        .frame(width: 36, height: 36)
    }
}

#Preview {
    VStack(spacing: 12) {
        CategoryCard(
            style: .fossil,
            name: "Fossil Fuels",
            totalGW: 3.30,
            percentOfDemand: 0.132,
            entries: [
                SourceEntry(id: "coal", label: "Coal", color: FuelType.coal.swatch,
                            valueGW: 0, percentOfDemand: 0.062),
                SourceEntry(id: "gas", label: "Gas", color: FuelType.gas.swatch,
                            valueGW: 1.85, percentOfDemand: 0.070)
            ]
        )
        CategoryCard(
            style: .renewable,
            name: "Renewables",
            totalGW: 9.84,
            percentOfDemand: 0.472,
            entries: [
                SourceEntry(id: "solar", label: "Solar", color: FuelType.solar.swatch,
                            valueGW: 14.65, percentOfDemand: 0.1465),
                SourceEntry(id: "wind", label: "Wind", color: FuelType.wind.swatch,
                            valueGW: 4.83, percentOfDemand: 0.0483),
                SourceEntry(id: "hydro", label: "Hydroelectric", color: FuelType.hydro.swatch,
                            valueGW: 0, percentOfDemand: 0)
            ]
        )
    }
    .padding()
    .background(Palette.pageBackground)
}
