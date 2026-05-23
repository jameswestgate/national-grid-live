import SwiftUI

struct StatusBarView: View {
    let live: LiveGrid

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
                kpi(label: "Time", value: Self.timeFormatter.string(from: live.asOf), unit: "")
                kpi(label: "Price", value: String(format: "%.2f", live.price), unit: "/MWh", prefix: "£")
                kpi(label: "Emissions", value: String(format: "%.0f", live.emissions), unit: "g/kWh")
            }
            .padding(.vertical, 14)
        }
    }

    private var rightCard: some View {
        Card {
            HStack(spacing: 0) {
                kpi(label: "Demand", value: String(format: "%.1f", live.demand), unit: "GW")
                operatorLabel("=")
                kpi(label: "Generation", value: String(format: "%.1f", live.generation), unit: "GW")
                operatorLabel("+")
                kpi(label: "Transfers", value: String(format: "%.1f", live.transfers), unit: "GW")
            }
            .padding(.vertical, 14)
        }
    }

    private func kpi(label: String, value: String, unit: String, prefix: String = "") -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.appSerif(.callout))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            HStack(spacing: 0) {
                if !prefix.isEmpty {
                    Text(prefix).font(.appSerif(.title3))
                }
                Text(value).font(.appSerif(.title3))
                Text(unit).font(.appSerif(.footnote)).foregroundStyle(.tertiary)
            }
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    private func operatorLabel(_ symbol: String) -> some View {
        Text(symbol)
            .font(.appSerif(.title2))
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mma"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f
    }()
}

#Preview("iPhone") {
    StatusBarView(live: .sample)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
