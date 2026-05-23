import Foundation

struct MockLiveProvider: LiveGridProvider {
    let sample: LiveGrid

    init(sample: LiveGrid = .sample) {
        self.sample = sample
    }

    func fetch() async throws -> LiveGrid {
        try? await Task.sleep(for: .milliseconds(200))
        return sample
    }
}

extension LiveGrid {
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
}
