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
        // The equation uses the site's display rule: each term rounded to 1 dp
        // BEFORE summing, so Demand = Generation + Transfers always adds up on
        // screen. Negative transfers flip the operator to "−" (Equation.php).
        Card {
            HStack(spacing: 0) {
                kpi(label: "Demand", value: String(format: "%.1f", stats.equationDemand), unit: "GW")
                operatorLabel("=")
                kpi(label: "Generation", value: String(format: "%.1f", stats.equationGeneration), unit: "GW")
                operatorLabel(stats.equationTransfers < 0 ? "−" : "+")
                kpi(label: "Transfers", value: String(format: "%.1f", abs(stats.equationTransfers)), unit: "GW")
            }
            .padding(.vertical, 14)
        }
    }

    private var priceText: String {
        guard let p = stats.price else { return "—" }
        // Round to the nearest whole £ — less screen real estate than Kate's site,
        // so the value stays short and the font never has to shrink. Below £10
        // the pence are most of the story (e.g. "-6.42"), so keep two decimals.
        return String(format: abs(p) < 10 ? "%.2f" : "%.0f", p)
    }

    private var emissionsText: String {
        guard let e = stats.emissions else { return "—" }
        return String(format: "%.0f", e)
    }

    private func kpi(label: String, value: String, unit: String, prefix: String = "") -> some View {
        VStack(spacing: 5) {
            // Same style as the "% of demand" captions on the cards below.
            Text(label)
                .font(.subheadline)
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
