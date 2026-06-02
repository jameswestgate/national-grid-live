import SwiftUI
import Charts

/// Y-axis spec computed with the site's algorithm (`Axes.php`): ONE shared
/// range per metric across ALL FOUR period series (day/week/year/all-time),
/// zero always included, the step from a fixed ladder keyed by the range, and
/// the bounds rounded outwards to step multiples. Switching tabs therefore
/// never rescales a graph, exactly like grid.iamkate.com.
struct MetricAxis {
    let minimum: Double
    let maximum: Double
    let step: Double

    init(values: [Double?]) {
        var lo = 0.0, hi = 0.0
        for v in values.compactMap({ $0 }) {
            lo = min(lo, v)
            hi = max(hi, v)
        }
        let range = hi - lo
        let step: Double =
            range > 2000 ? 500 :
            range > 1000 ? 200 :
            range > 500 ? 100 :
            range > 200 ? 50 :
            range > 100 ? 20 :
            range > 50 ? 10 :
            range > 20 ? 5 :
            range > 10 ? 2 : 1
        self.step = step
        self.minimum = step * (lo / step).rounded(.down)
        self.maximum = step * (hi / step).rounded(.up)
    }

    /// A gridline + label at every step, like the site.
    var gridValues: [Double] {
        Array(stride(from: minimum, through: maximum + step / 2, by: step))
    }
}

/// X-axis cadence per period tab, mirroring `Tabs.php`'s timeStep/timeFormat:
/// day = every 6 h ("8:00pm"), week = every day (full weekday name),
/// year = quarterly ("14/07/2025"), all-time = every year ("2024").
enum ChartXAxisStyle {
    case sixHourly, daily, quarterly, yearly
}

enum ChartAxis {
    /// The site's graphs are all 250px tall (`--graph-height` in grid.css).
    static let height: CGFloat = 250

    @AxisContentBuilder
    static func xAxisContent(for style: ChartXAxisStyle) -> some AxisContent {
        switch style {
        case .sixHourly:
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                    .font(.footnote)
                    .foregroundStyle(Color(.label))
            }
        case .daily:
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.weekday(.wide))
                    .font(.footnote)
                    .foregroundStyle(Color(.label))
            }
        case .quarterly:
            AxisMarks(values: .stride(by: .month, count: 3)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.day(.twoDigits).month(.twoDigits).year())
                    .font(.footnote)
                    .foregroundStyle(Color(.label))
            }
        case .yearly:
            AxisMarks(values: .stride(by: .year, count: 1)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.year())
                    .font(.footnote)
                    .foregroundStyle(Color(.label))
            }
        }
    }

    @AxisContentBuilder
    static func yAxisContent(for axis: MetricAxis, suffix: String, prefix: String = "") -> some AxisContent {
        AxisMarks(position: .leading, values: axis.gridValues) { value in
            AxisGridLine().foregroundStyle(Palette.graphLine)
            AxisValueLabel {
                if let d = value.as(Double.self) {
                    // The caption grey used by "% of demand" etc. across the cards.
                    Text("\(d < 0 ? "−" : "")\(prefix)\(String(format: "%.0f", abs(d)))\(suffix)")
                        .font(.footnote)
                        .foregroundStyle(Color(.secondaryLabel))
                }
            }
        }
    }
}

/// Single-line metric graph (Price, Emissions) drawn to the site's spec.
struct LineMetricChart: View {
    /// Used as the semantic name for Swift Charts accessibility; not rendered.
    let title: String
    let points: [TimedValue]
    let axis: MetricAxis
    let xAxis: ChartXAxisStyle
    var lineColor: Color = .primary
    var unitSuffix: String = ""
    var unitPrefix: String = ""

    var body: some View {
        Chart {
            ForEach(points) { p in
                if let v = p.value {
                    LineMark(
                        x: .value("Time", p.date),
                        y: .value(title, v)
                    )
                    .foregroundStyle(lineColor)
                    .interpolationMethod(.monotone)
                }
            }
        }
        .chartYScale(domain: axis.minimum...axis.maximum)
        .chartYAxis { ChartAxis.yAxisContent(for: axis, suffix: unitSuffix, prefix: unitPrefix) }
        .chartXAxis { ChartAxis.xAxisContent(for: xAxis) }
        .frame(height: ChartAxis.height)
    }
}

/// Multi-line graph over arbitrary named series — used for the site-matching
/// Demand graph (demand + fossils + renewables + others + transfers lines).
struct MultiLineSeriesChart: View {
    struct Line: Identifiable {
        let label: String
        let color: Color
        let values: [Double?]
        var id: String { label }
    }

    let dates: [Date]
    let lines: [Line]
    let axis: MetricAxis
    let xAxis: ChartXAxisStyle
    var unitSuffix: String = "GW"

    var body: some View {
        Chart {
            ForEach(lines) { line in
                ForEach(Array(zip(dates, line.values).enumerated()), id: \.offset) { _, pair in
                    if let v = pair.1 {
                        LineMark(
                            x: .value("Time", pair.0),
                            y: .value(line.label, v),
                            series: .value("Series", line.label)
                        )
                        .foregroundStyle(line.color)
                        .interpolationMethod(.monotone)
                    }
                }
            }
        }
        .chartYScale(domain: axis.minimum...axis.maximum)
        .chartYAxis { ChartAxis.yAxisContent(for: axis, suffix: unitSuffix) }
        .chartXAxis { ChartAxis.xAxisContent(for: xAxis) }
        .frame(height: ChartAxis.height)
    }
}

struct TimedValue: Identifiable {
    let date: Date
    let value: Double?
    var id: Date { date }
}

/// One legend entry: a small colour pill + the line's name.
struct ChartLegendEntry: Identifiable {
    let label: String
    let color: Color
    var id: String { label }
}

/// Wrapping legend shown under the multi-line graphs — mirrors the Android
/// app's chart legends: a 10pt colour dot, 5pt gap, label in the footnote
/// caption grey, entries flowing onto new rows as needed, 12pt below the plot.
struct ChartLegend: View {
    let entries: [ChartLegendEntry]

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 112), spacing: 8, alignment: .leading)],
            alignment: .leading,
            spacing: 6
        ) {
            ForEach(entries) { entry in
                HStack(spacing: 5) {
                    Circle()
                        .fill(entry.color)
                        .frame(width: 10, height: 10)
                    Text(entry.label)
                        .font(.footnote)
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)
                }
            }
        }
        .padding(.top, 12)
    }
}
