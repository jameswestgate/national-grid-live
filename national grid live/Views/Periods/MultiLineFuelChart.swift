import SwiftUI
import Charts

struct MultiLineFuelChart: View {
    let dates: [Date]
    let fuels: [FuelType: [Double?]]
    let granularity: Granularity

    private static let order: [FuelType] = [.gas, .coal, .wind, .solar, .hydro, .nuclear, .biomass, .pumped]

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
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text("\(Int(d))GW")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            ChartAxis.xAxisContent(for: granularity)
        }
        .frame(height: 200)
    }
}
