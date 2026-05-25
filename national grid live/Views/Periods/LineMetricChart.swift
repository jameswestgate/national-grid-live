import SwiftUI
import Charts

struct LineMetricChart: View {
    /// Used as the semantic name for Swift Charts accessibility; not rendered.
    let title: String
    let points: [TimedValue]
    var lineColor: Color = .primary
    var unitSuffix: String = ""
    var includeZero: Bool = false
    var granularity: Granularity = .day

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
            if includeZero {
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Palette.graphLine)
                    .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel {
                    if let d = value.as(Double.self) {
                        Text(yLabel(d))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            ChartAxis.xAxisContent(for: granularity)
        }
        .frame(height: 160)
    }

    private func yLabel(_ value: Double) -> String {
        let formatted: String
        if abs(value) >= 10 || value == 0 {
            formatted = String(format: "%.0f", value)
        } else {
            formatted = String(format: "%.1f", value)
        }
        return formatted + unitSuffix
    }
}

enum ChartAxis {
    @AxisContentBuilder
    static func xAxisContent(for granularity: Granularity) -> some AxisContent {
        switch granularity {
        case .halfHour:
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .hour:
            AxisMarks(values: .stride(by: .day, count: 1)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .day:
            AxisMarks(values: .stride(by: .month, count: 3)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.day(.twoDigits).month(.twoDigits).year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .month:
            AxisMarks(values: .stride(by: .year, count: 2)) { _ in
                AxisGridLine().foregroundStyle(Palette.graphLine)
                AxisValueLabel(format: .dateTime.year())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TimedValue: Identifiable {
    let date: Date
    let value: Double?
    var id: Date { date }
}
