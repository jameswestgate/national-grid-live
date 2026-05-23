import Foundation

struct LiveGrid: Sendable, Equatable {
    let asOf: Date
    let price: Double
    let emissions: Double
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
}
