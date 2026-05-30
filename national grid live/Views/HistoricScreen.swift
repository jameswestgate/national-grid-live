import SwiftUI

struct HistoricScreen: View {
    @Environment(GridStore.self) private var store
    @State private var selection: Period = .day
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ScreenHeader(title: "Historic") { showSettings = true }

                        Picker("Period", selection: $selection) {
                            ForEach(Period.allCases) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)

                        if let message = snapshotFailureMessage {
                            OfflineBanner(message: message) {
                                Task { await store.refresh() }
                            }
                        }

                        if let live = store.live, let snapshot = store.snapshot {
                            content(live: live, snapshot: snapshot,
                                    onScrollTo: { proxy.scrollTo($0, anchor: .center) })
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                        }
                    }
                    .padding(16)
                }
                .washBackground()
                .toolbar(.hidden, for: .navigationBar)
                .refreshable { await store.refresh() }
                .settingsSheet($showSettings)
            }
        }
    }

    @ViewBuilder
    private func content(live: LiveData, snapshot: Snapshot,
                         onScrollTo: @escaping (String) -> Void) -> some View {
        let series = series(for: selection, live: live, snapshot: snapshot)
        let dates = series.parsedDates
        let averages = PeriodAverages.from(series)

        StatusBarView(stats: averages, headline: ("Period", selection.displayName))

        LatestSection(stats: averages, onScrollTo: onScrollTo)

        chartsSection(series: series, dates: dates)
    }

    @ViewBuilder
    private func chartsSection(series: TimeSeries, dates: [Date]) -> some View {
        SectionHeader(title: "Trends")

        chartCard(title: "Price per MWh") {
            LineMetricChart(
                title: "Price per MWh",
                points: timedPoints(series.price, dates: dates),
                unitSuffix: "£",
                granularity: series.granularity
            )
        }

        chartCard(title: "Emissions per kWh") {
            LineMetricChart(
                title: "Emissions per kWh",
                points: timedPoints(series.emissions, dates: dates),
                unitSuffix: "g",
                granularity: series.granularity
            )
        }

        chartCard(title: "Demand") {
            LineMetricChart(
                title: "Demand",
                points: timedPoints(series.demand, dates: dates),
                unitSuffix: "GW",
                granularity: series.granularity
            )
        }

        chartCard(title: "Generation by source") {
            MultiLineFuelChart(
                dates: dates,
                fuels: series.fuels,
                granularity: series.granularity
            )
        }

        chartCard(title: "Transfers by interconnector") {
            MultiLineInterconnectorChart(
                dates: dates,
                interconnectors: series.interconnectors,
                granularity: series.granularity
            )
        }
    }

    private func chartCard<Chart: View>(title: String, @ViewBuilder chart: () -> Chart) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: title)
                chart()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .padding(.top, 8)
            }
        }
    }

    private func timedPoints(_ values: [Double?], dates: [Date]) -> [TimedValue] {
        zip(dates, values).map { TimedValue(date: $0.0, value: $0.1) }
    }

    private func series(for period: Period, live: LiveData, snapshot: Snapshot) -> TimeSeries {
        switch period {
        case .day:     live.day
        case .week:    live.week
        case .year:    snapshot.year
        case .allTime: snapshot.allTime
        }
    }

    private var snapshotFailureMessage: String? {
        if case .failed(let m) = store.snapshotState, store.snapshot != nil { return m }
        return nil
    }
}

#Preview {
    HistoricScreen()
        .environment(GridStore.mock())
}
