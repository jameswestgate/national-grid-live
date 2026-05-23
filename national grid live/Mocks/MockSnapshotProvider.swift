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
        let yearDates = (0..<14).map { offset -> String in
            let date = Calendar(identifier: .iso8601)
                .date(byAdding: .day, value: -13 + offset, to: Date.now)!
            return Snapshot.dayFormatter.string(from: date)
        }
        let allTimeDates = (0..<24).map { offset -> String in
            let date = Calendar(identifier: .iso8601)
                .date(byAdding: .month, value: -23 + offset, to: Date.now)!
            return Snapshot.monthFormatter.string(from: date)
        }

        return Snapshot(
            schemaVersion: 1,
            generated: .now,
            sources: .init(
                elexon: "Contains BMRS data © Elexon Limited copyright and database right 2026.",
                carbonIntensity: "Carbon intensity data © National Grid ESO and Oxford CS, CC BY 4.0.",
                neso: "Contains NESO Data Portal data, NESO Open Licence."
            ),
            year: .init(
                from: yearDates.first!,
                to: yearDates.last!,
                granularity: .day,
                dates: yearDates,
                price:      Snapshot.wave(yearDates.count, base: 95, amp: 35),
                emissions:  Snapshot.wave(yearDates.count, base: 130, amp: 60),
                demand:     Snapshot.wave(yearDates.count, base: 26, amp: 4),
                generation: Snapshot.wave(yearDates.count, base: 21, amp: 4),
                transfers:  Snapshot.wave(yearDates.count, base: 4, amp: 1.5),
                fuels: [
                    .gas:     Snapshot.wave(yearDates.count, base: 6, amp: 3),
                    .coal:    Array(repeating: 0.0, count: yearDates.count),
                    .wind:    Snapshot.wave(yearDates.count, base: 7, amp: 4),
                    .solar:   Snapshot.wave(yearDates.count, base: 3, amp: 2),
                    .hydro:   Snapshot.wave(yearDates.count, base: 0.3, amp: 0.1),
                    .nuclear: Snapshot.wave(yearDates.count, base: 2.5, amp: 0.3),
                    .biomass: Snapshot.wave(yearDates.count, base: 1.7, amp: 0.4),
                    .pumped:  Snapshot.wave(yearDates.count, base: 0, amp: 0.4)
                ],
                interconnectors: [
                    .france:      Snapshot.wave(yearDates.count, base: 2.8, amp: 1),
                    .norway:      Snapshot.wave(yearDates.count, base: 1.3, amp: 0.4),
                    .belgium:     Snapshot.wave(yearDates.count, base: 0.5, amp: 0.5),
                    .denmark:     Snapshot.wave(yearDates.count, base: 0.4, amp: 0.4),
                    .ireland:     Snapshot.wave(yearDates.count, base: -0.5, amp: 0.5),
                    .netherlands: Snapshot.wave(yearDates.count, base: 0.3, amp: 0.6)
                ]
            ),
            allTime: .init(
                from: allTimeDates.first!,
                to: allTimeDates.last!,
                granularity: .month,
                dates: allTimeDates,
                price:      Snapshot.wave(allTimeDates.count, base: 100, amp: 40),
                emissions:  Snapshot.wave(allTimeDates.count, base: 180, amp: 90),
                demand:     Snapshot.wave(allTimeDates.count, base: 28, amp: 5),
                generation: Snapshot.wave(allTimeDates.count, base: 23, amp: 5),
                transfers:  Snapshot.wave(allTimeDates.count, base: 4, amp: 2),
                fuels: [
                    .gas:     Snapshot.wave(allTimeDates.count, base: 9, amp: 4),
                    .coal:    Snapshot.wave(allTimeDates.count, base: 0.5, amp: 0.5),
                    .wind:    Snapshot.wave(allTimeDates.count, base: 6, amp: 3),
                    .solar:   Snapshot.wave(allTimeDates.count, base: 2, amp: 1.5),
                    .hydro:   Array(repeating: 0.3, count: allTimeDates.count),
                    .nuclear: Snapshot.wave(allTimeDates.count, base: 3, amp: 0.5),
                    .biomass: Snapshot.wave(allTimeDates.count, base: 1.8, amp: 0.5),
                    .pumped:  Snapshot.wave(allTimeDates.count, base: 0, amp: 0.3)
                ],
                interconnectors: [
                    .france:      Snapshot.wave(allTimeDates.count, base: 2.5, amp: 1),
                    .norway:      Snapshot.wave(allTimeDates.count, base: 1.0, amp: 0.5),
                    .belgium:     Snapshot.wave(allTimeDates.count, base: 0.4, amp: 0.5),
                    .denmark:     Snapshot.wave(allTimeDates.count, base: 0.3, amp: 0.3),
                    .ireland:     Snapshot.wave(allTimeDates.count, base: -0.3, amp: 0.5),
                    .netherlands: Snapshot.wave(allTimeDates.count, base: 0.2, amp: 0.5)
                ]
            )
        )
    }()

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM"
        return f
    }()

    static func wave(_ count: Int, base: Double, amp: Double) -> [Double?] {
        (0..<count).map { i in
            let t = Double(i) / Double(max(count - 1, 1))
            return base + amp * sin(t * .pi * 2)
        }
    }
}
