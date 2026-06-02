import SwiftUI
import Charts

/// The site's "Generation" graph: one line per fuel. Pumped storage is NOT a
/// generation line on the site (it lives in the Transfers graph).
struct MultiLineFuelChart: View {
    let dates: [Date]
    let fuels: [FuelType: [Double?]]
    let axis: MetricAxis
    let xAxis: ChartXAxisStyle

    /// Shared with the card's legend.
    static let order: [FuelType] = [.gas, .coal, .wind, .solar, .hydro, .nuclear, .biomass]

    var body: some View {
        Chart {
            ForEach(Self.order, id: \.self) { fuel in
                let series = fuels[fuel] ?? []
                ForEach(Array(zip(dates, series).enumerated()), id: \.offset) { _, pair in
                    if let v = pair.1 {
                        LineMark(
                            x: .value("Time", pair.0),
                            y: .value(fuel.displayName, v),
                            series: .value("Fuel", fuel.rawValue)
                        )
                        .foregroundStyle(fuel.swatch)
                        .interpolationMethod(.monotone)
                    }
                }
            }
        }
        .chartYScale(domain: axis.minimum...axis.maximum)
        .chartYAxis { ChartAxis.yAxisContent(for: axis, suffix: "GW") }
        .chartXAxis { ChartAxis.xAxisContent(for: xAxis) }
        .frame(height: ChartAxis.height)
    }
}
