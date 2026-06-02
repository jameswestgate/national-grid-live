import SwiftUI
import Charts

/// The site's "Transfers" graph: one line per interconnector country PLUS a
/// pumped-storage line (`Transfers::KEY_COMPONENTS` includes `pumped`).
struct MultiLineInterconnectorChart: View {
    let dates: [Date]
    let interconnectors: [Interconnector: [Double?]]
    let pumped: [Double?]
    let axis: MetricAxis
    let xAxis: ChartXAxisStyle

    /// The site draws the pumped line in `.pumped { color: #09c; }`. Shared
    /// with the card's legend.
    static let pumpedColor = Color(red: 0.0, green: 0x99 / 255.0, blue: 0xCC / 255.0)

    var body: some View {
        Chart {
            ForEach(Interconnector.allCases, id: \.self) { ic in
                let series = interconnectors[ic] ?? []
                ForEach(Array(zip(dates, series).enumerated()), id: \.offset) { _, pair in
                    if let v = pair.1 {
                        LineMark(
                            x: .value("Time", pair.0),
                            y: .value(ic.displayName, v),
                            series: .value("Interconnector", ic.rawValue)
                        )
                        .foregroundStyle(ic.swatch)
                        .interpolationMethod(.monotone)
                    }
                }
            }
            ForEach(Array(zip(dates, pumped).enumerated()), id: \.offset) { _, pair in
                if let v = pair.1 {
                    LineMark(
                        x: .value("Time", pair.0),
                        y: .value("Pumped storage", v),
                        series: .value("Interconnector", "pumped")
                    )
                    .foregroundStyle(Self.pumpedColor)
                    .interpolationMethod(.monotone)
                }
            }
        }
        .chartYScale(domain: axis.minimum...axis.maximum)
        .chartYAxis { ChartAxis.yAxisContent(for: axis, suffix: "GW") }
        .chartXAxis { ChartAxis.xAxisContent(for: xAxis) }
        .frame(height: ChartAxis.height)
    }
}
