import SwiftUI

struct StatusBarView: View {
    let stats: PeriodAverages
    /// First KPI cell — pass ("Time", "1:25pm") for Live, ("Period", "Past day") for Historic.
    let headline: (label: String, value: String)

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                leftCard
                rightCard
            }
            VStack(spacing: 16) {
                leftCard
                rightCard
            }
        }
    }

    private var leftCard: some View {
        Card {
            HStack(spacing: 0) {
                kpi(label: headline.label, value: headline.value, unit: "")
                kpi(label: "Price", value: priceText, unit: "/MWh", prefix: "£")
                kpi(label: "Emissions", value: emissionsText, unit: "g/kWh")
            }
            .padding(.vertical, 14)
        }
    }

    private var rightCard: some View {
        Card {
            HStack(spacing: 0) {
                kpi(label: "Demand", value: String(format: "%.1f", stats.demand), unit: "GW")
                operatorLabel("=")
                kpi(label: "Generation", value: String(format: "%.1f", stats.generation), unit: "GW")
                operatorLabel("+")
                kpi(label: "Transfers", value: String(format: "%.1f", stats.transfers), unit: "GW")
            }
            .padding(.vertical, 14)
        }
    }

    private var priceText: String {
        guard let p = stats.price else { return "—" }
        return String(format: "%.2f", p)
    }

    private var emissionsText: String {
        guard let e = stats.emissions else { return "—" }
        return String(format: "%.0f", e)
    }

    private func kpi(label: String, value: String, unit: String, prefix: String = "") -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.title2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Palette.dataText)
                }
                Text(value)
                    .font(.title2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Palette.dataText)
                Text(unit).font(.caption2).foregroundStyle(.secondary)
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

#Preview("Live") {
    StatusBarView(stats: LiveGrid.sample.asAverages, headline: ("Time", "1:25pm"))
        .padding()
        .background(Palette.pageBackground)
}

#Preview("Historic") {
    StatusBarView(stats: PeriodAverages.from(LiveData.sample.day), headline: ("Period", "Past day"))
        .padding()
        .background(Palette.pageBackground)
}
