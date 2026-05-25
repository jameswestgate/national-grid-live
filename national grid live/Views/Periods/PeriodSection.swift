import SwiftUI

struct PeriodSection: View {
    let live: LiveData
    let snapshot: Snapshot
    @State private var selection: Period = .day
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Card {
            VStack(spacing: 0) {
                PeriodSelector(selection: $selection)
                content
                    .padding(16)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        let series = series(for: selection)
        let dates = series.parsedDates
        let averages = PeriodAverages.from(series)

        VStack(spacing: 22) {
            PeriodStatsView(period: selection, averages: averages)

            GenerationDonut(
                generation: averages.generation,
                demand: averages.demand,
                fuels: averages.fuels,
                size: sizeClass == .regular ? 340 : 280
            )

            PeriodBreakdownView(averages: averages)

            VStack(spacing: 18) {
                chart("Price per MWh", values: series.price, dates: dates,
                      lineColor: .white, unitSuffix: "£")
                chart("Emissions per kWh", values: series.emissions, dates: dates,
                      lineColor: .white, unitSuffix: "g")
                chart("Demand", values: series.demand, dates: dates,
                      lineColor: .white, unitSuffix: "GW")

                MultiLineFuelChart(
                    title: "Generation",
                    dates: dates,
                    fuels: series.fuels,
                    granularity: series.granularity
                )

                MultiLineInterconnectorChart(
                    title: "Transfers",
                    dates: dates,
                    interconnectors: series.interconnectors,
                    granularity: series.granularity
                )
            }
        }
    }

    private func series(for period: Period) -> TimeSeries {
        switch period {
        case .day:     live.day
        case .week:    live.week
        case .year:    snapshot.year
        case .allTime: snapshot.allTime
        }
    }

    private func chart(_ title: String,
                       values: [Double?],
                       dates: [Date],
                       lineColor: Color,
                       unitSuffix: String,
                       includeZero: Bool = false) -> some View {
        let points = zip(dates, values).map { TimedValue(date: $0.0, value: $0.1) }
        return LineMetricChart(
            title: title,
            points: points,
            lineColor: lineColor,
            unitSuffix: unitSuffix,
            includeZero: includeZero,
            granularity: series(for: selection).granularity
        )
    }
}

#Preview {
    PeriodSection(live: .sample, snapshot: .sample)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
