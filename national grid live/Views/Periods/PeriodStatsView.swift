import SwiftUI

struct PeriodStatsView: View {
    let period: Period
    let averages: PeriodAverages

    var body: some View {
        VStack(spacing: 18) {
            row(left: ("Time", period.displayName, ""),
                middle: ("Price", priceText, "/MWh"),
                right: ("Emissions", emissionsText, "g/kWh"))

            HStack(alignment: .firstTextBaseline, spacing: 0) {
                column(label: "Demand", value: gwText(averages.demand))
                operatorLabel("=")
                column(label: "Generation", value: gwText(averages.generation))
                operatorLabel("+")
                column(label: "Transfers", value: gwText(averages.transfers))
            }
        }
    }

    private var priceText: String {
        guard let p = averages.price else { return "—" }
        return String(format: "£%.2f", p)
    }

    private var emissionsText: String {
        guard let e = averages.emissions else { return "—" }
        return String(format: "%.0f", e)
    }

    private func gwText(_ v: Double) -> String {
        String(format: "%.1f", v)
    }

    private func row(left: (String, String, String),
                     middle: (String, String, String),
                     right: (String, String, String)) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            kpi(label: left.0,   value: left.1,   unit: left.2)
            kpi(label: middle.0, value: middle.1, unit: middle.2)
            kpi(label: right.0,  value: right.1,  unit: right.2)
        }
    }

    private func kpi(label: String, value: String, unit: String) -> some View {
        column(label: label, value: value, unit: unit)
    }

    private func column(label: String, value: String, unit: String = "") -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value).font(.title2.weight(.bold).monospacedDigit())
                if !unit.isEmpty {
                    Text(unit).font(.caption2).foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    private func operatorLabel(_ symbol: String) -> some View {
        Text(symbol)
            .font(.title2)
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }
}

#Preview {
    PeriodStatsView(period: .day, averages: .from(LiveData.sample.day))
        .padding()
        .background(Palette.contentBackground)
        .preferredColorScheme(.dark)
}
