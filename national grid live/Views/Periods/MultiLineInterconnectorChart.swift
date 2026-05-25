import SwiftUI
import Charts

struct MultiLineInterconnectorChart: View {
    let dates: [Date]
    let interconnectors: [Interconnector: [Double?]]
    let granularity: Granularity

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
            RuleMark(y: .value("Zero", 0))
                .foregroundStyle(Palette.graphLine)
                .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
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
