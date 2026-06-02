import SwiftUI

struct HistoricScreen: View {
    @Environment(GridStore.self) private var store
    @State private var selection: Period = .day
    @State private var showSettings = false
    /// Pinned chart tooltip — persists after the touch lifts, cleared by
    /// tapping anywhere off the graphs or switching period.
    @State private var chartSelection = ChartSelectionState()
    /// Settings → Historic charts → "Show graph legends" (default off).
    @AppStorage(AppSettings.showGraphLegendsKey) private var showGraphLegends = false

    init() {
        // Screenshot hook: `-startPeriod day|week|year|all` selects the initial
        // period (the segmented picker can't be tapped by simctl).
        switch UserDefaults.standard.string(forKey: "startPeriod") {
        case "week": _selection = State(initialValue: .week)
        case "year": _selection = State(initialValue: .year)
        case "all":  _selection = State(initialValue: .allTime)
        default: break
        }
    }

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
                        // .large grows the segmented control's own height (the
                        // native knob — frame() only pads around it); the padding
                        // adds a little margin above and below.
                        .controlSize(.large)
                        .padding(.vertical, 4)

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
                // A tap that lands anywhere other than a chart's own selection
                // gesture dismisses the pinned tooltip.
                .onTapGesture { chartSelection.clear() }
                .onChange(of: selection) { _, _ in chartSelection.forceClear() }
            }
        }
    }

    @ViewBuilder
    private func content(live: LiveData, snapshot: Snapshot,
                         onScrollTo: @escaping (String) -> Void) -> some View {
        let series = series(for: selection, live: live, snapshot: snapshot)
        let averages = PeriodAverages.from(series)

        StatusBarView(stats: averages, headline: ("Period", selection.displayName))

        LatestSection(stats: averages, onScrollTo: onScrollTo)

        chartsSection(
            series: chartSeries(for: selection, base: series),
            axes: SharedAxes(live: live, snapshot: snapshot),
            xAxis: xAxisStyle(for: selection)
        )
    }

    // MARK: - Charts (drawn to the site's spec)

    @ViewBuilder
    private func chartsSection(series: TimeSeries, axes: SharedAxes, xAxis: ChartXAxisStyle) -> some View {
        let dates = series.parsedDates

        chartCard(title: "Price per MWh") {
            LineMetricChart(
                title: "Price per MWh",
                points: timedPoints(series.price, dates: dates),
                axis: axes.price,
                xAxis: xAxis,
                unitPrefix: "£",
                tooltipDecimals: 2,
                selectionState: chartSelection,
                selectionID: "price"
            )
        }

        chartCard(title: "Emissions per kWh") {
            LineMetricChart(
                title: "Emissions per kWh",
                points: timedPoints(series.emissions, dates: dates),
                axis: axes.emissions,
                xAxis: xAxis,
                unitSuffix: "g",
                selectionState: chartSelection,
                selectionID: "emissions"
            )
        }

        chartCard(title: "Demand") {
            // The site's Demand graph is FIVE lines: demand plus the equation
            // groups (fossils / renewables / others / transfers).
            let lines = DemandLines(series: series)
            VStack(alignment: .leading, spacing: 0) {
                MultiLineSeriesChart(
                    dates: dates,
                    lines: [
                        .init(label: "Demand", color: .primary, values: lines.demand),
                        .init(label: "Fossil fuels", color: FuelCategory.fossil.bannerColor, values: lines.fossils),
                        .init(label: "Renewables", color: FuelCategory.renewable.bannerColor, values: lines.renewables),
                        .init(label: "Other sources", color: FuelCategory.other.bannerColor, values: lines.others),
                        .init(label: "Transfers", color: Color(.systemGray2), values: lines.transfers)
                    ],
                    axis: axes.demand,
                    xAxis: xAxis,
                    selectionState: chartSelection,
                    selectionID: "demand"
                )
                if showGraphLegends {
                    ChartLegend(entries: [
                        .init(label: "Demand", color: .primary),
                        .init(label: "Fossil fuels", color: FuelCategory.fossil.bannerColor),
                        .init(label: "Renewables", color: FuelCategory.renewable.bannerColor),
                        .init(label: "Other sources", color: FuelCategory.other.bannerColor),
                        .init(label: "Transfers", color: Color(.systemGray2))
                    ])
                }
            }
        }

        chartCard(title: "Generation") {
            VStack(alignment: .leading, spacing: 0) {
                MultiLineFuelChart(
                    dates: dates,
                    fuels: series.fuels,
                    axis: axes.generation,
                    xAxis: xAxis,
                    selectionState: chartSelection,
                    selectionID: "generation"
                )
                if showGraphLegends {
                    ChartLegend(entries: MultiLineFuelChart.order.map {
                        .init(label: $0.displayName, color: $0.swatch)
                    })
                }
            }
        }

        chartCard(title: "Transfers") {
            VStack(alignment: .leading, spacing: 0) {
                MultiLineInterconnectorChart(
                    dates: dates,
                    interconnectors: series.interconnectors,
                    pumped: series.fuels[.pumped] ?? [],
                    axis: axes.transfers,
                    xAxis: xAxis,
                    selectionState: chartSelection,
                    selectionID: "transfers"
                )
                if showGraphLegends {
                    ChartLegend(entries: Interconnector.allCases.map {
                        .init(label: $0.displayName, color: $0.swatch)
                    } + [.init(label: "Pumped storage", color: MultiLineInterconnectorChart.pumpedColor)])
                }
            }
        }
    }

    private func chartCard<Chart: View>(title: String, @ViewBuilder chart: () -> Chart) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: title)
                chart()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    // + CardHeader's 4pt ≈ 22pt of air between the heading and
                    // the top axis label, matching the app's other card graphics.
                    .padding(.top, 18)
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

    /// The series each tab PLOTS, matching the rows the site's graphs draw:
    /// day = 48 half-hours, week = 7 days (native), year = 52 Monday-start
    /// weeks (grouped from the snapshot's daily rows), all-time = one point
    /// per calendar year (grouped from the monthly rows).
    private func chartSeries(for period: Period, base: TimeSeries) -> TimeSeries {
        switch period {
        case .day, .week:
            base
        case .year:
            grouped(base, granularity: .day) { Self.utcCalendar.dateInterval(of: .weekOfYear, for: $0)?.start ?? $0 }
        case .allTime:
            grouped(base, granularity: .month) { Self.utcCalendar.dateInterval(of: .year, for: $0)?.start ?? $0 }
        }
    }

    private func xAxisStyle(for period: Period) -> ChartXAxisStyle {
        switch period {
        case .day:     .sixHourly
        case .week:    .daily
        case .year:    .quarterly
        case .allTime: .yearly
        }
    }

    /// Buckets a series into coarser groups (mean per metric per group), used
    /// to derive the chart-only weekly/yearly series.
    private func grouped(_ s: TimeSeries, granularity: Granularity, keyOf: (Date) -> Date) -> TimeSeries {
        let sourceDates = s.parsedDates
        var orderedKeys: [Date] = []
        var groups: [Date: [Int]] = [:]
        for (i, d) in sourceDates.enumerated() {
            let k = keyOf(d)
            if groups[k] == nil { orderedKeys.append(k) }
            groups[k, default: []].append(i)
        }

        func mean(_ arr: [Double?], _ idx: [Int]) -> Double? {
            let vals = idx.compactMap { $0 < arr.count ? arr[$0] : nil }
            return vals.isEmpty ? nil : vals.reduce(0, +) / Double(vals.count)
        }
        func gather(_ arr: [Double?]) -> [Double?] {
            orderedKeys.map { mean(arr, groups[$0] ?? []) }
        }

        let f = DateFormatter()
        f.calendar = Self.utcCalendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = (granularity == .month) ? "yyyy-MM" : "yyyy-MM-dd"
        let dateStrings = orderedKeys.map { f.string(from: $0) }

        return TimeSeries(
            from: dateStrings.first ?? "",
            to: dateStrings.last ?? "",
            granularity: granularity,
            dates: dateStrings,
            price: gather(s.price),
            emissions: gather(s.emissions),
            demand: gather(s.demand),
            generation: gather(s.generation),
            transfers: gather(s.transfers),
            fuels: Dictionary(uniqueKeysWithValues: FuelType.allCases.map { ($0, gather(s.fuels[$0] ?? [])) }),
            interconnectors: Dictionary(uniqueKeysWithValues: Interconnector.allCases.map { ($0, gather(s.interconnectors[$0] ?? [])) })
        )
    }

    private static let utcCalendar: Calendar = {
        var c = Calendar(identifier: .iso8601)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        return c
    }()

    private var snapshotFailureMessage: String? {
        if case .failed(let m) = store.snapshotState, store.snapshot != nil { return m }
        return nil
    }
}

/// The site's shared per-metric axes (`Axes.php`): each metric's range is
/// scanned across ALL FOUR period series — per LINE, not per total — so every
/// tab shares identical scales and switching periods never rescales a graph.
private struct SharedAxes {
    let price: MetricAxis
    let emissions: MetricAxis
    let demand: MetricAxis
    let generation: MetricAxis
    let transfers: MetricAxis

    init(live: LiveData, snapshot: Snapshot) {
        let all = [live.day, live.week, snapshot.year, snapshot.allTime]
        price = MetricAxis(values: all.flatMap(\.price))
        emissions = MetricAxis(values: all.flatMap(\.emissions))
        demand = MetricAxis(values: all.flatMap { DemandLines(series: $0).allValues })
        generation = MetricAxis(values: all.flatMap { s in
            FuelType.allCases.filter { $0 != .pumped }.flatMap { s.fuels[$0] ?? [] }
        })
        transfers = MetricAxis(values: all.flatMap { s in
            Interconnector.allCases.flatMap { s.interconnectors[$0] ?? [] } + (s.fuels[.pumped] ?? [])
        })
    }
}

/// The five lines of the site's Demand graph, derived per bucket from a series.
private struct DemandLines {
    let demand: [Double?]
    let fossils: [Double?]
    let renewables: [Double?]
    let others: [Double?]
    let transfers: [Double?]

    init(series: TimeSeries) {
        func sum(_ types: [FuelType]) -> [Double?] {
            (0..<series.dates.count).map { i in
                let vals = types.compactMap { t -> Double? in
                    guard let arr = series.fuels[t], i < arr.count else { return nil }
                    return arr[i]
                }
                return vals.isEmpty ? nil : vals.reduce(0, +)
            }
        }
        demand = series.demand
        fossils = sum([.gas, .coal])
        renewables = sum([.wind, .solar, .hydro])
        others = sum([.nuclear, .biomass])
        transfers = series.transfers
    }

    var allValues: [Double?] { demand + fossils + renewables + others + transfers }
}

#Preview {
    HistoricScreen()
        .environment(GridStore.mock())
}
