import Foundation

struct MockSnapshotProvider: SnapshotProvider {
    let sample: Snapshot

    init(sample: Snapshot = .sample) {
        self.sample = sample
    }

    func fetch() async throws -> Snapshot {
        try? await Task.sleep(for: .milliseconds(300))
        return sample
    }
}

extension Snapshot {
    static let sample: Snapshot = makeSample()

    private static func makeSample() -> Snapshot {
        let now = Date.now
        let cal = Calendar(identifier: .iso8601)

        let yearDates = (0..<365).map { offset -> String in
            let date = cal.date(byAdding: .day, value: -(364 - offset), to: now)!
            return MockWaveform.dayFormatter.string(from: date)
        }
        let monthDates = (0..<60).map { offset -> String in
            let date = cal.date(byAdding: .month, value: -(59 - offset), to: now)!
            return MockWaveform.monthFormatter.string(from: date)
        }

        return Snapshot(
            schemaVersion: 1,
            generated: now,
            sources: .init(
                elexon: "Contains BMRS data © Elexon Limited copyright and database right 2026.",
                carbonIntensity: "Carbon intensity data © National Grid ESO and Oxford CS, CC BY 4.0.",
                neso: "Contains NESO Data Portal data, NESO Open Licence."
            ),
            year:    MockWaveform.buildSeries(dates: yearDates,  granularity: .day,   cycles: 1),
            allTime: MockWaveform.buildSeries(dates: monthDates, granularity: .month, cycles: 1, drift: -0.3)
        )
    }
}
