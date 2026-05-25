import SwiftUI

struct SourceEntry: Identifiable {
    let id: String
    let label: String
    let color: Color
    let valueGW: Double?
    let percentOfDemand: Double?
}

struct SourceBarRow: View {
    let entry: SourceEntry
    /// Bar fill ratio, 0...1, normalised by the parent category.
    let barProgress: Double

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(entry.label)
                .font(.callout)
                .foregroundStyle(.primary)
                .frame(width: 110, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            MiniBar(color: entry.color, progress: barProgress)
                .frame(height: 6)
                .frame(maxWidth: .infinity)

            VStack(alignment: .trailing, spacing: 1) {
                Text(percentText)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(entry.color)
                Text(gwText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .frame(minWidth: 64, alignment: .trailing)
        }
    }

    private var percentText: String {
        guard let p = entry.percentOfDemand else { return "—" }
        let sign = p < 0 ? "−" : ""
        return sign + String(format: "%.1f%%", abs(p) * 100)
    }

    private var gwText: String {
        guard let gw = entry.valueGW else { return "—" }
        let sign = gw < 0 ? "−" : ""
        return sign + String(format: "%.2f GW", abs(gw))
    }
}

private struct MiniBar: View {
    let color: Color
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(1, progress)) * proxy.size.width)
            }
        }
    }
}

#Preview {
    VStack(spacing: 14) {
        SourceBarRow(
            entry: SourceEntry(id: "coal", label: "Coal",
                               color: FuelType.coal.swatch,
                               valueGW: 0, percentOfDemand: 0.062),
            barProgress: 0.47
        )
        SourceBarRow(
            entry: SourceEntry(id: "gas", label: "Gas",
                               color: FuelType.gas.swatch,
                               valueGW: 1.85, percentOfDemand: 0.070),
            barProgress: 0.53
        )
    }
    .padding()
    .background(Palette.contentBackground)
}
