import Foundation

struct MockLiveProvider: LiveDataProvider {
    let sample: LiveData

    init(sample: LiveData = .sample) {
        self.sample = sample
    }

    func fetch() async throws -> LiveData {
        try? await Task.sleep(for: .milliseconds(200))
        // Re-synthesise relative to "now" each fetch so the data appears to refresh.
        return LiveData.makeSample(now: .now)
    }
}

extension LiveData {
    /// Static sample for `#Preview` blocks where deterministic data matters.
    static let sample: LiveData = makeSample(now: .now)

    static func makeSample(now: Date) -> LiveData {
        let day = MockWaveform.makeDay(now: now)
        let week = MockWaveform.makeWeek(now: now)
        return LiveData(
            current: LiveGrid(from: day, at: now),
            day: day,
            week: week
        )
    }
}

extension LiveGrid {
    /// Static sample matching the historical 9:50pm screenshot — used by preview
    /// blocks that pre-date the mock synthesis API.
    static let sample = LiveGrid(
        asOf: .now,
        price: 140.47,
        emissions: 190,
        demand: 25.6,
        generation: 21.6,
        transfers: 4.0,
        fuels: [
            .gas: 11.90,
            .coal: 0.0,
            .wind: 5.45,
            .solar: 0.0,
            .hydro: 0.26,
            .nuclear: 2.32,
            .biomass: 1.71,
            .pumped: 0.29
        ],
        interconnectors: [
            .france: 3.50,
            .norway: 1.40,
            .belgium: 0.23,
            .denmark: 0.0,
            .ireland: -0.96,
            .netherlands: -0.46
        ]
    )

    /// Build the current-point view from the last entry of a time series.
    init(from series: TimeSeries, at asOf: Date) {
        self.asOf = asOf
        self.price = series.price.last??.rounded(toPlaces: 2) ?? 0
        self.emissions = (series.emissions.last??.rounded(toPlaces: 0)) ?? 0
        self.demand = series.demand.last??.rounded(toPlaces: 2) ?? 0
        self.generation = series.generation.last??.rounded(toPlaces: 2) ?? 0
        self.transfers = series.transfers.last??.rounded(toPlaces: 2) ?? 0

        var fuelsOut: [FuelType: Double] = [:]
        for f in FuelType.allCases {
            fuelsOut[f] = (series.fuels[f]?.last ?? nil)?.rounded(toPlaces: 2) ?? 0
        }
        self.fuels = fuelsOut

        var icOut: [Interconnector: Double] = [:]
        for ic in Interconnector.allCases {
            icOut[ic] = (series.interconnectors[ic]?.last ?? nil)?.rounded(toPlaces: 2) ?? 0
        }
        self.interconnectors = icOut
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
}
