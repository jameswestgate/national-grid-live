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
    static let sample: Snapshot = {
        let now = Date.now
        return Snapshot(
            schemaVersion: 1,
            generated: now,
            sources: .init(
                elexon: "Contains BMRS data © Elexon Limited copyright and database right 2026.",
                carbonIntensity: "Carbon intensity data © National Grid ESO and Oxford CS, CC BY 4.0.",
                neso: "Contains NESO Data Portal data, NESO Open Licence."
            ),
            year:    MockWaveform.makeYear(now: now),
            allTime: MockWaveform.makeAllTime(now: now)
        )
    }()
}
