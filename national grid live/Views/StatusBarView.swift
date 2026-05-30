import SwiftUI

/// Compact KPI strip shown above the generation breakdown: the snapshot time /
/// period, market price and carbon intensity on the left, with the
/// demand = generation + transfers balance on the right.
struct StatusBarView: View {
    let stats: PeriodAverages
    /// First KPI cell — ("Time", "1:45pm") on Live, ("Period", "Past day") on Historic.
    let headline: (label: String, value: String)

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                leftCard
                rightCard
            }
            VStack(spacing: 12) {
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
        VStack(spacing: 5) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Palette.dataText)
                }
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(Palette.dataText)
                Text(unit).font(.caption2).foregroundStyle(.secondary)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 3)
    }

    private func operatorLabel(_ symbol: String) -> some View {
        Text(symbol)
            .font(.title3)
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }
}

#Preview("Live") {
    StatusBarView(stats: LiveGrid.sample.asAverages, headline: ("Time", "1:25pm"))
        .padding()
        .background(Palette.pageBackground)
}
