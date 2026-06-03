import SwiftUI
import Charts

/// The site's "Generation" graph: one line per fuel. Pumped storage is NOT a
/// generation line on the site (it lives in the Transfers graph).
struct MultiLineFuelChart: View {
    let dates: [Date]
    let fuels: [FuelType: [Double?]]
    let axis: MetricAxis
    let xAxis: ChartXAxisStyle

    let selectionState: ChartSelectionState
    let selectionID: String

    /// Shared with the card's legend.
    static let order: [FuelType] = [.gas, .coal, .wind, .solar, .hydro, .nuclear, .biomass]

    @State private var selection: Date?

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
            if let snapped = snappedSelection {
                ChartSelectionMark(date: snapped.date, title: xAxis.tooltipTitle(for: snapped.date), rows: snapped.rows)
            }
        }
        .chartXSelection(value: $selection)
        .onChange(of: selection) { _, new in
            if let new { selectionState.set(selectionID, date: new) }
        }
        .chartYScale(domain: axis.minimum...axis.maximum)
        .chartYAxis { ChartAxis.yAxisContent(for: axis, suffix: "GW") }
        .chartXAxis { ChartAxis.xAxisContent(for: xAxis) }
        .frame(height: ChartAxis.height)
    }

    private var snappedSelection: (date: Date, rows: [ChartSelectionRow])? {
        guard let pinned = selectionState.date(for: selectionID),
              let i = chartNearestIndex(to: pinned, in: dates) else { return nil }
        let rows = Self.order.compactMap { fuel -> ChartSelectionRow? in
            guard let arr = fuels[fuel], i < arr.count, let v = arr[i] else { return nil }
            // Skip lines that round to 0.00 (e.g. coal) — they only add clutter.
            guard abs(v) >= 0.005 else { return nil }
            return ChartSelectionRow(
                label: fuel.displayName,
                color: fuel.swatch,
                value: "\(v < 0 ? "−" : "")\(String(format: "%.2f", abs(v)))",
                unit: "GW"
            )
        }
        return rows.isEmpty ? nil : (dates[i], rows)
    }
}
