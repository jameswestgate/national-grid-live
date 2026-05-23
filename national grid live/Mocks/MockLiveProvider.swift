import Foundation

struct MockLiveProvider: LiveDataProvider {
    let sample: LiveData

    init(sample: LiveData = .sample) {
        self.sample = sample
    }

    func fetch() async throws -> LiveData {
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

extension LiveData {
    static let sample: LiveData = {
        let now = Date.now
        let cal = Calendar(identifier: .iso8601)

        let dayDates = (0..<48).map { offset -> String in
            let date = cal.date(byAdding: .minute, value: -30 * (47 - offset), to: now)!
            return MockWaveform.timestampFormatter.string(from: date)
        }
        let weekDates = (0..<168).map { offset -> String in
            let date = cal.date(byAdding: .hour, value: -(167 - offset), to: now)!
            return MockWaveform.timestampFormatter.string(from: date)
        }

        return LiveData(
            current: .sample,
            day:  MockWaveform.buildSeries(dates: dayDates,  granularity: .halfHour, cycles: 1),
            week: MockWaveform.buildSeries(dates: weekDates, granularity: .hour,     cycles: 7)
        )
    }()
}
