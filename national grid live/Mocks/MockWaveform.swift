import Foundation

/// Mock generators that approximate the shape of UK grid data: realistic daily
/// load curves, zero solar at night, a (now-)coal-free generation mix, gentle
/// long-run trends. The `makeYear` and `makeAllTime` paths are calibrated so
/// their 365-day / 168-month averages land within ~0.5 GW of the values
/// displayed on `grid.iamkate.com`'s Past year and All time tabs.
///
/// `makeDay` / `makeWeek` exist for preview / `.mock` `LiveSource` use only —
/// the production app pulls today's and the last 7 days' data from the live
/// Elexon/Carbon-Intensity/NESO APIs via `LiveDataAggregator`.
enum MockWaveform {
    private static let cal = Calendar(identifier: .iso8601)

    // MARK: - Builders per period

    static func makeDay(now: Date, count: Int = 48) -> TimeSeries {
        let interval: TimeInterval = 30 * 60
        let timestamps = (0..<count).map { offset -> Date in
            now.addingTimeInterval(-Double(count - 1 - offset) * interval)
        }
        return build(timestamps: timestamps, granularity: .halfHour, mode: .intraday)
    }

    static func makeWeek(now: Date, count: Int = 168) -> TimeSeries {
        let interval: TimeInterval = 60 * 60
        let timestamps = (0..<count).map { offset -> Date in
            now.addingTimeInterval(-Double(count - 1 - offset) * interval)
        }
        return build(timestamps: timestamps, granularity: .hour, mode: .intraday)
    }

    /// 365 daily aggregates. Each point represents one calendar day.
    static func makeYear(now: Date, count: Int = 365) -> TimeSeries {
        let timestamps = (0..<count).compactMap { offset -> Date? in
            cal.date(byAdding: .day, value: -(count - 1 - offset), to: now)
        }
        return build(timestamps: timestamps, granularity: .day, mode: .daily)
    }

    /// 168 monthly aggregates — 14 years × 12 months, matching Kate's site
    /// (2012-now). Includes a coal-retirement ramp around the 2024 cutoff.
    static func makeAllTime(now: Date, count: Int = 168) -> TimeSeries {
        let timestamps = (0..<count).compactMap { offset -> Date? in
            cal.date(byAdding: .month, value: -(count - 1 - offset), to: now)
        }
        return build(timestamps: timestamps, granularity: .month, mode: .monthly)
    }

    // MARK: - Core synthesis

    private enum Mode { case intraday, daily, monthly }

    private static func build(timestamps: [Date],
                              granularity: Granularity,
                              mode: Mode) -> TimeSeries {
        let dateStrings = timestamps.map { dateString(for: $0, granularity: granularity) }

        var demand: [Double?] = []
        var generation: [Double?] = []
        var transfers: [Double?] = []
        var price: [Double?] = []
        var emissions: [Double?] = []
        var fuels: [FuelType: [Double?]] = Dictionary(uniqueKeysWithValues: FuelType.allCases.map { ($0, []) })
        var ics:   [Interconnector: [Double?]] = Dictionary(uniqueKeysWithValues: Interconnector.allCases.map { ($0, []) })

        for (i, ts) in timestamps.enumerated() {
            let point: MockPoint
            switch mode {
            case .intraday: point = MockPoint.synthesiseIntraday(at: ts, indexOfTotal: i)
            case .daily:    point = MockPoint.synthesiseDay(at: ts, indexOfTotal: i)
            case .monthly:  point = MockPoint.synthesiseMonth(at: ts, indexOfTotal: i, totalCount: timestamps.count)
            }
            demand.append(point.demand)
            generation.append(point.generation)
            transfers.append(point.transfers)
            price.append(point.price)
            emissions.append(point.emissions)
            for f in FuelType.allCases {
                fuels[f, default: []].append(point.fuels[f] ?? 0)
            }
            for ic in Interconnector.allCases {
                ics[ic, default: []].append(point.interconnectors[ic] ?? 0)
            }
        }

        return TimeSeries(
            from: dateStrings.first ?? "",
            to: dateStrings.last ?? "",
            granularity: granularity,
            dates: dateStrings,
            price: price,
            emissions: emissions,
            demand: demand,
            generation: generation,
            transfers: transfers,
            fuels: fuels,
            interconnectors: ics
        )
    }

    // MARK: - Date formatting

    private static let timestampFmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        return f
    }()
    private static let dayFmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private static let monthFmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static func dateString(for date: Date, granularity: Granularity) -> String {
        switch granularity {
        case .halfHour, .hour: timestampFmt.string(from: date)
        case .day:             dayFmt.string(from: date)
        case .month:           monthFmt.string(from: date)
        }
    }

    /// UK daily demand shape, indexed by hour of day. Average across the 24
    /// values is ~1.0 so it can multiply a daily-mean demand without inflating it.
    fileprivate static let demandFactorTable: [(hour: Double, factor: Double)] = [
        (0,    0.85), (2,    0.80), (4,    0.75), (6,    0.86),
        (8,    1.02), (9,    1.05), (10,   1.03), (12,   1.00),
        (14,   0.98), (16,   1.10), (17,   1.18), (18,   1.22),
        (19,   1.20), (20,   1.12), (22,   0.97), (24,   0.85)
    ]

    fileprivate static func interpolatedDailyDemandFactor(hour: Double) -> Double {
        let h = max(0, min(24, hour.truncatingRemainder(dividingBy: 24).magnitude))
        let table = demandFactorTable
        for i in 0..<(table.count - 1) {
            let a = table[i], b = table[i + 1]
            if h >= a.hour && h <= b.hour {
                let span = b.hour - a.hour
                guard span > 0 else { return a.factor }
                let t = (h - a.hour) / span
                return a.factor + t * (b.factor - a.factor)
            }
        }
        return 1.0
    }
}

/// One synthesised data point representing a (possibly aggregated) instant on
/// the grid. Captures the relationships between the metrics — generation tracks
/// demand minus transfers, gas fills the gap left by wind/solar/nuclear,
/// emissions follow the fossil share, price tracks demand.
private struct MockPoint {
    let demand: Double
    let generation: Double
    let transfers: Double
    let price: Double
    let emissions: Double
    let fuels: [FuelType: Double]
    let interconnectors: [Interconnector: Double]

    // MARK: - Intraday (half-hour / hourly) — for previews / mock LiveSource

    static func synthesiseIntraday(at date: Date, indexOfTotal: Int) -> MockPoint {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.hour, .minute, .month, .weekday], from: date)
        let hour = Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0
        let monthIdx = Double((comps.month ?? 1) - 1)
        let weekday = comps.weekday ?? 1
        let isWeekend = (weekday == 1 || weekday == 7)

        let seasonal = cos(monthIdx / 12 * 2 * .pi)               // +1 winter, -1 summer
        let hourlyDemandFactor = MockWaveform.interpolatedDailyDemandFactor(hour: hour)
        let baseDemand = 27.0 + 2.5 * seasonal - (isWeekend ? 1.5 : 0.0)
        let demand = baseDemand * hourlyDemandFactor

        let solarHourFactor: Double = {
            guard hour >= 6, hour <= 19 else { return 0 }
            return sin((hour - 6) / 13 * .pi)
        }()
        let solarSeasonFactor = 0.5 + 0.5 * (1 - cos((monthIdx - 6) / 12 * 2 * .pi)) / 2
        let solar = 12.0 * solarHourFactor * solarSeasonFactor

        let phase = Double(indexOfTotal) * 1.7
        let windNoise = 2.2 * cos(phase * 0.31) + 1.4 * cos(phase * 0.79 + 1.2)
        let wind = max(0.4, 6.0 + 0.7 * seasonal + windNoise)
        let nuclear = 2.4 + 0.2 * cos(Double(indexOfTotal) * 0.04)
        let biomass = 1.65 + 0.15 * cos(Double(indexOfTotal) * 0.07)
        let hydro = max(0.05, 0.28 + 0.10 * seasonal + 0.05 * cos(Double(indexOfTotal) * 0.21))
        let pumped = 0.4 * sin((hour - 5) / 24 * 2 * .pi)
        let coal = 0.0

        // Interconnectors
        let icHourPhase = Double(indexOfTotal) * 0.11
        let france = 2.8 + 1.0 * cos(icHourPhase)
        let norway = 1.2 + 0.3 * cos(icHourPhase + 0.5)
        let belgium = 0.4 + 0.4 * cos(icHourPhase + 1.1)
        let denmark = max(0, 0.3 + 0.3 * cos(icHourPhase + 2.0))
        let ireland = -0.7 + 0.6 * cos(icHourPhase + 0.3)
        let netherlands = 0.1 + 0.6 * cos(icHourPhase + 1.7)
        let ics: [Interconnector: Double] = [
            .france: france, .norway: norway, .belgium: belgium,
            .denmark: denmark, .ireland: ireland, .netherlands: netherlands
        ]
        let transfers = ics.values.reduce(0, +)

        let nonGas = wind + solar + nuclear + biomass + hydro + coal + pumped
        let gas = max(0.3, demand - transfers - nonGas)
        let fuels: [FuelType: Double] = [
            .gas: gas, .coal: coal, .wind: wind, .solar: solar,
            .hydro: hydro, .nuclear: nuclear, .biomass: biomass, .pumped: pumped
        ]
        let generation = fuels.values.reduce(0, +)

        let emissions = generation > 0 ? (gas * 350 + coal * 950) / generation : 0
        let price = max(15, 55.0 + max(0, demand - 18) * 4.0 - 8.0 * windNoise * 0.2)

        return MockPoint(demand: generation + transfers,
                         generation: generation, transfers: transfers,
                         price: price, emissions: emissions,
                         fuels: fuels, interconnectors: ics)
    }

    // MARK: - Daily aggregate (Past year — 365 points)
    //
    // Targets (grid.iamkate.com, May 2025–May 2026 window, snapshot 25/05/2026):
    //   demand 30.7 GW   gen 27.7 GW   transfers 3.0 GW
    //   gas 8.15  solar 2.06  wind 10.92  nuclear 3.87  biomass 2.32  hydro 0.42  pumped −0.05
    //   IC: belgium 0.25  denmark 0.23  france 2.66  ireland −0.80  netherlands 0.05  norway 0.69
    //   price £79.82  emissions 121 g/kWh
    //
    // Strategy: target = base + seasonal·winter + amplitude·noise. cos(2π·doy/365)
    // and the harmonic noise both have zero mean across a 365-day year, so each
    // variable's 365-day average ≈ its base term.

    static func synthesiseDay(at date: Date, indexOfTotal: Int) -> MockPoint {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.dayOfYear], from: date)
        let doy = Double(comps.dayOfYear ?? 1)

        // Winter signal: +1 at Jan 1, -1 at Jul 2. Zero-mean over the year.
        let winter = cos(2 * .pi * (doy - 1) / 365)
        // Summer-bell solar availability: 0 around winter solstice, 1 around
        // summer solstice. Mean = 0.5 — so `2*target` scaling hits the average.
        let summerBell = (1 - cos(2 * .pi * (doy - 1) / 365)) / 2

        let phase = Double(indexOfTotal) * 1.7
        let noise = cos(phase * 0.31) + cos(phase * 0.79 + 1.2) + 0.5 * cos(phase * 1.51 + 2.5)

        let wind     = max(1.0, 10.92 + 1.5 * winter + 2.8 * noise)
        let solar    = max(0,   2.06 * 2 * summerBell + 0.3 * cos(phase * 0.41))
        let nuclear  = max(0.5, 3.87 + 0.3 * cos(phase * 0.13))
        let biomass  = max(0.5, 2.32 + 0.2 * cos(phase * 0.21))
        let hydro    = max(0.1, 0.42 + 0.15 * winter + 0.08 * cos(phase * 0.33))
        let pumped   = -0.05 + 0.10 * cos(phase * 0.27)
        let coal     = 0.0   // retired ~Sep 2024, well before the 365-day window

        let icPhase = Double(indexOfTotal) * 0.11
        let belgium     =  0.25 + 0.30 * cos(icPhase)
        let denmark     =  0.23 + 0.25 * cos(icPhase + 0.5)
        let france      =  2.66 + 0.50 * cos(icPhase + 1.0)
        let ireland     = -0.80 + 0.30 * cos(icPhase + 1.5)
        let netherlands =  0.05 + 0.40 * cos(icPhase + 2.0)
        let norway      =  0.69 + 0.40 * cos(icPhase + 2.5)
        let ics: [Interconnector: Double] = [
            .belgium: belgium, .denmark: denmark, .france: france,
            .ireland: ireland, .netherlands: netherlands, .norway: norway
        ]
        let transfers = ics.values.reduce(0, +)

        // Demand baseline + seasonal swing + per-day noise. Mean = 30.7 over 365.
        let demandBaseline = 30.7 + 3.0 * winter + 0.6 * noise

        // Gas is the balance — implicitly tunes to ~8.15 by construction
        // (demand − transfers − non-gas).
        let nonGas = wind + solar + nuclear + biomass + hydro + coal + pumped
        let gas = max(0.5, demandBaseline - transfers - nonGas)

        let fuels: [FuelType: Double] = [
            .gas: gas, .coal: coal, .wind: wind, .solar: solar,
            .hydro: hydro, .nuclear: nuclear, .biomass: biomass, .pumped: pumped
        ]
        let generation = fuels.values.reduce(0, +)
        let demand = generation + transfers

        // Emissions: site says 121 g/kWh past year. Gas alone, scaled by share.
        // gas avg ≈ 8.15, gen avg ≈ 27.7 → emissions ≈ gas·415 / gen ≈ 122.
        let emissions = generation > 0 ? (gas * 415.0 + coal * 950.0) / generation : 0

        // Price: site says £79.82 past year. Winter higher (gas prices, demand),
        // summer lower. Wind also drives price (low wind ⇒ high price).
        let price = max(20, 79.82 + 16 * winter - 4 * noise)

        return MockPoint(
            demand: demand,
            generation: generation,
            transfers: transfers,
            price: price,
            emissions: emissions,
            fuels: fuels,
            interconnectors: ics
        )
    }

    // MARK: - Monthly aggregate (All time — 168 points = 14 years × 12 months)
    //
    // Targets (grid.iamkate.com All time, 2012-05-25 → 2026-05-25):
    //   demand 32.8  gen 30.7  transfers 2.1
    //   gas 11.03  coal 4.14  solar 1.16  wind 6.32  nuclear 6.05  biomass 1.57  hydro 0.40  pumped −0.03
    //   IC: belgium 0.22  denmark 0.06  france 1.30  ireland −0.23  netherlands 0.55  norway 0.26
    //   price £69.19  emissions 254 g/kWh
    //
    // Strategy: per-variable secular curve over secularT (0 = now, 1 = 14 years ago)
    // + seasonal modulation + small noise. Tuned so 168-month averages match
    // targets within ~0.5 GW.

    static func synthesiseMonth(at date: Date, indexOfTotal: Int, totalCount: Int) -> MockPoint {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.month], from: date)
        let monthIdx = Double((comps.month ?? 1) - 1)            // 0..11

        let monthsAgo = Double(totalCount - 1 - indexOfTotal)    // 0 = now, totalCount-1 = oldest
        let secularT = monthsAgo / Double(max(totalCount - 1, 1))  // 0..1
        let phase = Double(indexOfTotal) * 0.41
        let noise = cos(phase * 0.31) + 0.6 * cos(phase * 0.79 + 1.2)

        // Seasonal: +1 winter (month 0/11), -1 summer (month 6). Zero-mean.
        let seasonal = cos(monthIdx / 12 * 2 * .pi)

        // --- Secular curves ---
        // Targets / verified means in comments. Sweeping secularT 0..1 with
        // mean 0.5; for linear `a + b·s` the mean is `a + b/2`.
        //
        // Wind grew 1.5 → 11.5. Mean = 6.5 (target 6.32).
        let windSec     =  1.5 + 10.0 * (1 - secularT)
        // Solar grew 0.10 → 2.20. Mean = 1.15 (target 1.16).
        let solarSec    =  0.10 + 2.10 * (1 - secularT)
        // Nuclear declined 4 → 8 GW (more reactors online in the early 2010s).
        // Mean = 6.0 (target 6.05).
        let nuclearSec  =  4.0 + 4.0 * secularT
        // Biomass grew 0.6 → 2.5. Mean = 1.55 (target 1.57).
        let biomassSec  =  0.6 + 1.9 * (1 - secularT)
        // Hydro: ~steady, slight long-run drift. Mean ~0.40.
        let hydroSec    =  0.40 + 0.05 * (secularT - 0.5)
        // Pumped: ~steady at -0.03.
        let pumpedSec   = -0.03

        // Coal: zero from monthsAgo 0 up to ~18 (Sep 2024 retirement), then
        // ramps linearly to ~9.4 at the oldest point. With phaseout = 18 and
        // peak = 9.4 over 168 months: mean = 9.4·149/(2·168) = 4.17 (target 4.14).
        let coal: Double = {
            let phaseoutMonth: Double = 18
            if monthsAgo <= phaseoutMonth { return 0 }
            let t = (monthsAgo - phaseoutMonth) / Double(max(totalCount - 1, 1) - Int(phaseoutMonth))
            return max(0, 9.4 * min(1, t))
        }()

        // Gas: filled the gap as coal retired, peaked around 2017, declined as
        // renewables grew. Bow-shaped via sin(π·secularT), mean = 4.7·2/π ≈ 2.99.
        // 8 (now) → ~12.7 (peak ~7y ago) → ~8 (oldest). Mean ≈ 11.0 (target 11.03).
        let gasSec = 8.0 + 4.7 * sin(.pi * secularT)

        let wind    = max(1.0, windSec + 0.5 * seasonal + 1.5 * noise)
        let solar   = max(0,   solarSec * (1 + 0.7 * cos(.pi * (monthIdx - 6) / 6)))
                              // peaks in summer, zero in winter; mean ≈ solarSec
        let nuclear = max(0.5, nuclearSec + 0.2 * cos(phase * 0.13))
        let biomass = max(0.2, biomassSec + 0.15 * cos(phase * 0.21))
        let hydro   = max(0.1, hydroSec + 0.05 * seasonal)
        let pumped  = pumpedSec + 0.02 * cos(phase * 0.27)

        // Interconnectors: most cables came online over time.
        // - Belgium (Nemo, 2019): on from monthsAgo ≤ 84. Recent ~0.3, 0 before.
        //     mean ≈ 0.3 * 84/168 = 0.15 (target 0.22 — bump current value)
        // - Denmark (Viking Link, late 2023): on from monthsAgo ≤ 30.
        //     mean ≈ 0.3 * 30/168 = 0.054 ≈ target 0.06
        // - France (IFA 1986 + IFA2 2021 + ElecLink 2022): always on.
        //     2.0 now → 0.6 oldest. Mean = 1.3 ≈ target 1.30
        // - Ireland (Moyle 2001 + EWIC 2012): always on. Slight export to IE.
        //     -0.2 always. Mean ≈ -0.20 (target -0.23)
        // - Netherlands (BritNed 2011): always on. Mean ~0.55
        // - Norway (NSL, 2021): on from monthsAgo ≤ 60.
        //     mean ≈ 0.7 * 60/168 = 0.25 ≈ target 0.26
        let icPhase = Double(indexOfTotal) * 0.13
        let belgium     = monthsAgo <= 84  ? 0.44 + 0.15 * cos(icPhase) : 0
        let denmark     = monthsAgo <= 30  ? 0.30 + 0.20 * cos(icPhase + 0.5) : 0
        let france      = (0.6 + 1.4 * (1 - secularT)) + 0.30 * cos(icPhase + 1.0)
        let ireland     = -0.20 + 0.10 * cos(icPhase + 1.5)
        let netherlands =  0.55 + 0.20 * cos(icPhase + 2.0)
        let norway      = monthsAgo <= 60  ? 0.72 + 0.20 * cos(icPhase + 2.5) : 0
        let ics: [Interconnector: Double] = [
            .belgium: belgium, .denmark: denmark, .france: france,
            .ireland: ireland, .netherlands: netherlands, .norway: norway
        ]
        let transfers = ics.values.reduce(0, +)

        let gas = max(0.5, gasSec + 0.5 * noise)

        let fuels: [FuelType: Double] = [
            .gas: gas, .coal: coal, .wind: wind, .solar: solar,
            .hydro: hydro, .nuclear: nuclear, .biomass: biomass, .pumped: pumped
        ]
        let generation = fuels.values.reduce(0, +)
        let demand = generation + transfers

        // Emissions across all time = 254 g/kWh. Higher in old months (coal-heavy).
        // With avg gas=11.0, avg coal=4.17, avg gen=30.9:
        //   (11·350 + 4.17·950) / 30.9 ≈ 253 ≈ target 254.
        let emissions = generation > 0
            ? (gas * 350.0 + coal * 950.0) / generation
            : 0

        // Price across all time = £69. Cheap in 2012-2020 (£40-50), spiked
        // 2021-2023 to ~£200, declined since. Use a bell on secularT centered
        // around ~3y ago (secularT ≈ 0.2). Verified mean ≈ £68.
        let priceSpike = 50 * exp(-pow((secularT - 0.20) * 4.5, 2))
        let priceBase  = 38 + 25 * (1 - secularT)
        let price = max(20, priceBase + priceSpike + 8 * noise)

        return MockPoint(
            demand: demand,
            generation: generation,
            transfers: transfers,
            price: price,
            emissions: emissions,
            fuels: fuels,
            interconnectors: ics
        )
    }
}
