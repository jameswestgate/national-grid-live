import Foundation

enum MockWaveform {
    static func buildSeries(
        dates: [String],
        granularity: Granularity,
        cycles: Double,
        drift: Double = 0
    ) -> TimeSeries {
        let n = dates.count
        return TimeSeries(
            from: dates.first ?? "",
            to: dates.last ?? "",
            granularity: granularity,
            dates: dates,
            price:      wave(n, base: 95,  amp: 35,  cycles: cycles, drift: drift * 30),
            emissions:  wave(n, base: 130, amp: 60,  cycles: cycles, drift: drift * 60),
            demand:     wave(n, base: 26,  amp: 4,   cycles: cycles, drift: drift),
            generation: wave(n, base: 21,  amp: 4,   cycles: cycles, drift: drift),
            transfers:  wave(n, base: 4,   amp: 1.5, cycles: cycles, drift: drift),
            fuels: [
                .gas:     wave(n, base: 6,    amp: 3,   cycles: cycles, drift: drift * 2),
                .coal:    wave(n, base: 0.0,  amp: 0,   cycles: cycles, drift: 0),
                .wind:    wave(n, base: 7,    amp: 4,   cycles: cycles, drift: -drift * 2),
                .solar:   wave(n, base: 3,    amp: 2,   cycles: cycles, drift: -drift),
                .hydro:   wave(n, base: 0.3,  amp: 0.1, cycles: cycles),
                .nuclear: wave(n, base: 2.5,  amp: 0.3, cycles: cycles),
                .biomass: wave(n, base: 1.7,  amp: 0.4, cycles: cycles),
                .pumped:  wave(n, base: 0,    amp: 0.4, cycles: cycles)
            ],
            interconnectors: [
                .france:      wave(n, base: 2.8,  amp: 1,   cycles: cycles),
                .norway:      wave(n, base: 1.3,  amp: 0.4, cycles: cycles),
                .belgium:     wave(n, base: 0.5,  amp: 0.5, cycles: cycles),
                .denmark:     wave(n, base: 0.4,  amp: 0.4, cycles: cycles),
                .ireland:     wave(n, base: -0.5, amp: 0.5, cycles: cycles),
                .netherlands: wave(n, base: 0.3,  amp: 0.6, cycles: cycles)
            ]
        )
    }

    static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return f
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

    static func wave(_ count: Int, base: Double, amp: Double, cycles: Double = 1, drift: Double = 0) -> [Double?] {
        (0..<count).map { i in
            let t = Double(i) / Double(max(count - 1, 1))
            return base + drift * t + amp * sin(t * .pi * 2 * cycles)
        }
    }
}
