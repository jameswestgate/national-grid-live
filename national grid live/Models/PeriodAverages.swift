import Foundation

struct PeriodAverages: Sendable, Equatable {
    let price: Double?
    let emissions: Double?
    let demand: Double
    let generation: Double
    let transfers: Double
    let fuels: [FuelType: Double]
    let interconnectors: [Interconnector: Double]

    func share(_ value: Double) -> Double {
        guard demand > 0 else { return 0 }
        return value / demand
    }

    // MARK: Equation display values (match grid.iamkate.com exactly)
    //
    // The site rounds each category total and transfers to 1 dp BEFORE summing
    // (State/Demand.php), so the displayed "Demand = Generation + Transfers"
    // always adds up on screen; the Generation panel headline GW uses the same
    // rounded-sum (PieChart.php). Percentages, by contrast, use the
    // FULL-precision values (Datum::getTotal()) — keep `share(_:)` for those.

    /// Generation as displayed in the equation: Σ of 1 dp-rounded category totals.
    var equationGeneration: Double {
        r1(categoryTotal(.fossil)) + r1(categoryTotal(.renewable)) + r1(categoryTotal(.other))
    }

    /// Transfers as displayed in the equation: 1 dp-rounded (may be negative).
    var equationTransfers: Double { r1(transfers) }

    /// Demand as displayed in the equation: sum of the two rounded terms above.
    var equationDemand: Double { equationGeneration + equationTransfers }

    private func r1(_ value: Double) -> Double { (value * 10).rounded() / 10 }

    func categoryTotal(_ category: FuelCategory) -> Double {
        fuels.reduce(into: 0.0) { acc, kv in
            if kv.key.category == category { acc += kv.value }
        }
    }

    var interconnectorsTotal: Double {
        interconnectors.values.reduce(0, +)
    }

    static func from(_ series: TimeSeries) -> PeriodAverages {
        PeriodAverages(
            price:      mean(series.price),
            emissions:  mean(series.emissions),
            demand:     mean(series.demand) ?? 0,
            generation: mean(series.generation) ?? 0,
            transfers:  mean(series.transfers) ?? 0,
            fuels:      series.fuels.mapValues { mean($0) ?? 0 },
            interconnectors: series.interconnectors.mapValues { mean($0) ?? 0 }
        )
    }

    private static func mean(_ values: [Double?]) -> Double? {
        let present = values.compactMap { $0 }
        guard !present.isEmpty else { return nil }
        return present.reduce(0, +) / Double(present.count)
    }
}
