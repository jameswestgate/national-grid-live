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
