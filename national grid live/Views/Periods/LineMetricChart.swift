import SwiftUI
import Charts

struct LineMetricChart: View {
    let title: String
    let points: [TimedValue]
    var lineColor: Color = Palette.accent
    var unitSuffix: String = ""
    var includeZero: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.appSerif(.callout))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

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
                                .font(.appSerif(.caption))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine().foregroundStyle(Palette.graphLine)
                    AxisValueLabel()
                        .font(.appSerif(.caption))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 160)
        }
    }

    private func yLabel(_ value: Double) -> String {
        let formatted: String
        if abs(value) >= 1000 {
            formatted = String(format: "%.0f", value)
        } else if abs(value) >= 10 || value == 0 {
            formatted = String(format: "%.0f", value)
        } else {
            formatted = String(format: "%.1f", value)
        }
        return formatted + unitSuffix
    }
}

struct TimedValue: Identifiable {
    let date: Date
    let value: Double?
    var id: Date { date }
}

#Preview {
    let series = Snapshot.sample.day
    let dates = series.parsedDates
    let pts = zip(dates, series.price).map { TimedValue(date: $0.0, value: $0.1) }
    return LineMetricChart(title: "Price per MWh", points: pts, lineColor: .white, unitSuffix: "£")
        .padding()
        .background(Palette.contentBackground)
        .preferredColorScheme(.dark)
}
