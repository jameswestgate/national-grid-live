import SwiftUI

struct SourceRow: View {
    let label: String
    let swatch: Color
    let valueGW: Double?
    let percent: Double?
    var outlinedSwatch: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            swatchView
            Text(label)
            Spacer(minLength: 8)
            valueText
                .frame(width: 90, alignment: .trailing)
                .monospacedDigit()
            percentText
                .frame(width: 60, alignment: .trailing)
                .monospacedDigit()
        }
        .font(.callout)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var swatchView: some View {
        if outlinedSwatch {
            RoundedRectangle(cornerRadius: 2)
                .stroke(swatch, lineWidth: 2)
                .frame(width: 14, height: 14)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(swatch)
                .frame(width: 14, height: 14)
        }
    }

    private var valueText: some View {
        HStack(spacing: 0) {
            if let gw = valueGW {
                let sign = gw < 0 ? "−" : ""
                let magnitude = abs(gw)
                Text(sign + String(format: "%.2f", magnitude))
            } else {
                Text("—")
            }
            Text("GW").foregroundStyle(.tertiary)
        }
    }

    private var percentText: some View {
        HStack(spacing: 0) {
            if let p = percent {
                let sign = p < 0 ? "−" : ""
                let magnitude = abs(p) * 100
                Text(sign + String(format: "%.1f", magnitude))
            } else {
                Text("—")
            }
            Text("%").foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        SourceRow(label: "Gas", swatch: FuelType.gas.swatch, valueGW: 11.90, percent: 0.464)
        SourceRow(label: "Wind", swatch: FuelType.wind.swatch, valueGW: 5.45, percent: 0.213)
        SourceRow(label: "Ireland", swatch: Interconnector.ireland.swatch, valueGW: -0.96, percent: -0.037, outlinedSwatch: true)
        SourceRow(label: "Battery storage", swatch: FuelType.pumped.swatch, valueGW: nil, percent: nil, outlinedSwatch: true)
    }
    .background(Palette.contentBackground)
    .preferredColorScheme(.dark)
}
