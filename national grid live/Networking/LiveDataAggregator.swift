import Foundation
import os

/// Implements `LiveDataProvider` by polling the three public APIs, merging
/// the deltas into an append-only on-disk store, and composing the result
/// into a `LiveData` (current point + 30-min past-day + 30-min past-week).
///
/// Design notes:
/// - On every refresh we ask each API for `[lastBucketInCache, now]` so we
///   only ever pull the few new buckets since the last refresh.
/// - The required window reaches back to the UTC midnight 7 days before
///   today's (the site's "Past week" = the 7 most recent complete UTC days,
///   excluding today). When a source's cache doesn't reach that far — first
///   launch, upgrade, or a long offline gap — its whole window is re-fetched
///   once (FUELINST ~8 MB; market index chunked to ≤7-day requests).
/// - The store trims everything older than that window start on every refresh.
struct LiveDataAggregator: LiveDataProvider {
    let elexon: ElexonClient
    let carbon: CarbonIntensityClient
    let neso:   NESOClient
    let cache:  JSONCache<LiveDataStore>
    let now:    @Sendable () -> Date

    private static let log = Logger(subsystem: "org.crainiate.national-grid-live", category: "live")

    init(elexon: ElexonClient = .init(),
         carbon: CarbonIntensityClient = .init(),
         neso:   NESOClient = .init(),
         cacheFilename: String = "live-store.json",
         now: @escaping @Sendable () -> Date = { .now }) throws {
        self.elexon = elexon
        self.carbon = carbon
        self.neso   = neso
        self.cache  = try JSONCache(filename: cacheFilename)
        self.now    = now
    }

    // MARK: - LiveDataProvider

    func cachedValue() -> LiveData? {
        guard let store = cache.read(), !store.generation.isEmpty else { return nil }
        return compose(from: store, now: now())
    }

    func fetch() async throws -> LiveData {
        var store = cache.read() ?? LiveDataStore()
        let nowDate = now()

        // The site's "Past week" averages the 7 most recent COMPLETE UTC days
        // (excluding today), so the store must reach back to the UTC midnight
        // 7 days before today's — up to ~8 days of data. When a source's cache
        // doesn't reach that far (first launch, upgrade, long offline gap) we
        // re-fetch its whole window once; afterwards refreshes are incremental
        // from the newest cached bucket, as before.
        let coverageStart = APITime.bucket(nowDate, interval: 24 * 60 * 60)
            .addingTimeInterval(-7 * 24 * 60 * 60)
        let cutoff = coverageStart

        func fetchFrom(latest: Date?, earliest: Date?) -> Date {
            // 1h slack so a missing bucket right at the boundary doesn't force
            // a full re-fetch on every refresh.
            guard let latest, let earliest,
                  earliest <= coverageStart.addingTimeInterval(60 * 60) else { return coverageStart }
            return latest
        }
        let genFrom   = fetchFrom(latest: store.latestGenerationTime, earliest: store.earliestGenerationTime)
        let emisFrom  = fetchFrom(latest: store.latestEmissionsTime,  earliest: store.earliestEmissionsTime)
        let priceFrom = fetchFrom(latest: store.latestPriceTime,      earliest: store.earliestPriceTime)
        let embedFrom = fetchFrom(latest: store.latestEmbeddedTime,   earliest: store.earliestEmbeddedTime)

        // Fetch the four sources in parallel. (Market index is chunked — the
        // endpoint rejects ranges over 7 days; FUELINST and Carbon Intensity
        // both accept the full ~8-day window in one request.)
        async let genItems    = elexon.fetchFuelInst(from: genFrom, to: nowDate)
        async let priceItems  = fetchMarketIndexChunked(from: priceFrom, to: nowDate)
        async let emisItems   = carbon.fetchRange(from: emisFrom, to: nowDate)
        async let embedItems  = neso.fetchEmbedded(from: embedFrom, to: nowDate)

        // Merge each into the store. Any one source failing is non-fatal — we
        // log it and proceed with the others (the offline banner surfaces it).
        do {
            for item in try await genItems {
                let bucket = APITime.bucket(APITime.parse(item.startTime) ?? nowDate, interval: 5 * 60)
                let key = APITime.iso(bucket)
                store.generation[key, default: [:]][item.fuelType] = item.generation
            }
        } catch {
            Self.log.warning("generation fetch failed: \(error.localizedDescription)")
        }

        do {
            for item in try await emisItems {
                guard let v = item.value, let from = APITime.parse(item.from) else { continue }
                let key = APITime.iso(APITime.bucket(from, interval: 30 * 60))
                store.emissions[key] = v
            }
        } catch {
            Self.log.warning("emissions fetch failed: \(error.localizedDescription)")
        }

        do {
            for item in try await priceItems {
                guard let from = APITime.parse(item.startTime) else { continue }
                let key = APITime.iso(APITime.bucket(from, interval: 30 * 60))
                store.price[key] = item.price
            }
        } catch {
            Self.log.warning("price fetch failed: \(error.localizedDescription)")
        }

        do {
            for row in try await embedItems {
                let key = APITime.iso(APITime.bucket(row.timestamp, interval: 30 * 60))
                store.embedded[key] = .init(windMW: row.embeddedWindMW, solarMW: row.embeddedSolarMW)
            }
        } catch {
            Self.log.warning("embedded (NESO) fetch failed: \(error.localizedDescription)")
        }

        store.trim(olderThan: cutoff)
        store.lastFetchedAt = nowDate
        cache.write(store)

        return compose(from: store, now: nowDate)
    }

    /// Lightweight path for **widgets**: fetch only a small recent window from
    /// each source and compose ONLY the current `LiveGrid` — no day/week series
    /// and no large on-disk store. The full `fetch()` pulls ~8 days of FUELINST
    /// (~8 MB) and builds two `TimeSeries`, which would blow a widget
    /// extension's tight (~30 MB) memory budget; a few hours is a few hundred
    /// rows. Reuses `currentPoint(store:now:)` verbatim so the numbers match the
    /// app and grid.iamkate.com exactly. Reads/writes nothing on disk.
    func fetchCurrentOnly(window: TimeInterval = 3 * 60 * 60) async throws -> LiveGrid {
        let nowDate = now()
        let from = nowDate.addingTimeInterval(-window)
        var store = LiveDataStore()

        // The window is < 7 days, so market index needs no chunking.
        async let genItems   = elexon.fetchFuelInst(from: from, to: nowDate)
        async let priceItems = elexon.fetchMarketIndex(from: from, to: nowDate)
        async let emisItems  = carbon.fetchRange(from: from, to: nowDate)
        async let embedItems = neso.fetchEmbedded(from: from, to: nowDate)

        // Any one source failing is non-fatal — compose with whatever arrived.
        if let items = try? await genItems {
            for item in items {
                let bucket = APITime.bucket(APITime.parse(item.startTime) ?? nowDate, interval: 5 * 60)
                store.generation[APITime.iso(bucket), default: [:]][item.fuelType] = item.generation
            }
        }
        if let items = try? await emisItems {
            for item in items {
                guard let v = item.value, let f = APITime.parse(item.from) else { continue }
                store.emissions[APITime.iso(APITime.bucket(f, interval: 30 * 60))] = v
            }
        }
        if let items = try? await priceItems {
            for item in items {
                guard let f = APITime.parse(item.startTime) else { continue }
                store.price[APITime.iso(APITime.bucket(f, interval: 30 * 60))] = item.price
            }
        }
        if let rows = try? await embedItems {
            for row in rows {
                store.embedded[APITime.iso(APITime.bucket(row.timestamp, interval: 30 * 60))] =
                    .init(windMW: row.embeddedWindMW, solarMW: row.embeddedSolarMW)
            }
        }

        return currentPoint(store: store, now: nowDate)
    }

    /// The market-index endpoint rejects ranges over 7 days; fetch in chunks.
    private func fetchMarketIndexChunked(from: Date, to: Date) async throws -> [ElexonClient.MarketIndexEnvelope.Item] {
        var items: [ElexonClient.MarketIndexEnvelope.Item] = []
        var chunkStart = from
        let maxChunk: TimeInterval = 6.5 * 24 * 60 * 60
        while chunkStart < to {
            let chunkEnd = min(chunkStart.addingTimeInterval(maxChunk), to)
            items += try await elexon.fetchMarketIndex(from: chunkStart, to: chunkEnd)
            chunkStart = chunkEnd
        }
        return items
    }

    // MARK: - Compose LiveData

    /// Turn the raw cache into the view-ready `LiveData`:
    /// - `current`: latest 5-min bucket of FUELINST data + matching 30-min
    ///   emissions/price/embedded buckets
    /// - `day`:     the last 48 COMPLETE half-hours (matches the site)
    /// - `week`:    the 7 most recent complete UTC days, excluding today
    ///              (matches the site), in hourly buckets
    func compose(from store: LiveDataStore, now: Date) -> LiveData {
        // The site's day/week views average only COMPLETE half-hours: "Past day"
        // is literally `ORDER BY time DESC LIMIT 48` over past_half_hours, whose
        // newest row is floor((latest 5-min reading − 25 min)/30 min) — the same
        // rule as the live anchor. Ending at `now` instead would include a
        // partial trailing bucket (a single 5-min reading weighted as a full
        // half-hour in the period mean), dragging fast-moving values — the
        // interconnectors especially — ~0.01-0.02 GW off the site's figures.
        let latestReading = store.generation.keys.max().flatMap { APITime.parse($0) } ?? now
        let lastComplete = APITime.bucket(latestReading.addingTimeInterval(-25 * 60), interval: 30 * 60)

        // "Past week" matches the site exactly: the mean of the 7 most recent
        // COMPLETE UTC days, EXCLUDING the partial current day (Database.php:
        // `past_days ORDER BY time DESC LIMIT 1,7` — skip today's row, take 7).
        // Hourly buckets across complete days weight each day equally, just
        // like her AVG over the 7 daily rows.
        let todayMidnight = APITime.bucket(latestReading, interval: 24 * 60 * 60)
        let weekStart = todayMidnight.addingTimeInterval(-7 * 24 * 60 * 60)

        let dayStart = lastComplete.addingTimeInterval(-47 * 30 * 60)

        // The week series is 7 DAILY points — the same `past_days` rows the
        // site's week tab plots (its graphs label one point per weekday).
        let day  = buildSeries(store: store, from: dayStart,  to: lastComplete, granularity: .halfHour)
        let week = buildSeries(store: store, from: weekStart,
                               to: todayMidnight.addingTimeInterval(-24 * 60 * 60), granularity: .day)
        let current = currentPoint(store: store, now: now)
        return LiveData(current: current, day: day, week: week)
    }

    // MARK: - Current point

    /// Composes a `LiveGrid` that matches the website's "current" state. The
    /// site's rule (verbatim from her repo's `Database.php`): the live state is
    /// `array_merge(latest past_half_hours row, latest past_five_minutes row)`.
    /// The latest 5-minute FUELINST row supplies the displayed time, fuels and
    /// interconnectors; the latest *complete* half-hour row supplies emissions,
    /// price AND embedded solar/wind. A half-hour row only exists once complete:
    /// `floor((latest five-minute time − 25 min) / 30 min)` — so a reading at
    /// 14:00 pairs with the 13:30 half-hour even though NESO has already
    /// published a fresher 14:00 forecast row (the site never uses it live).
    ///
    /// Verified against the live site 2026-06-02 14:00Z: site Solar 8.21 = the
    /// 13:30 embedded row (the 14:00 row said 7.82); price £94.77 + emissions
    /// 129 also from 13:30. An earlier observation (09:15 slot showing the
    /// 08:30 price/emissions) matches the same rule: floor(08:50 / 30) = 08:30.
    ///
    /// Sources that lag beyond the anchor (Carbon Intensity actuals can be
    /// 30-60 min behind) fall back to their most recent value ≤ anchor — the
    /// site does the equivalent by propagating the previous row's values
    /// forward into newly created half-hour rows.
    private func currentPoint(store: LiveDataStore, now: Date) -> LiveGrid {
        // (1) The latest 5-min FUELINST slot: displayed time + fuel mix.
        guard let slotKey = store.generation.keys.max(),
              let slotStart = APITime.parse(slotKey),
              let mwByCode = store.generation[slotKey], !mwByCode.isEmpty else {
            return fallback(store: store, now: now)
        }

        // (2) Anchor: the latest COMPLETE half-hour = floor((slot − 25min)/30min).
        let anchorStart = APITime.bucket(slotStart.addingTimeInterval(-25 * 60), interval: 30 * 60)
        let anchorKey = APITime.iso(anchorStart)

        // Decode FUELINST. Codes that don't map to a UI-visible FuelType
        // (BESS battery, OTHER misc) are deliberately dropped — the website's
        // displayed Generation total excludes them, and including them here
        // produces a consistent ~OTHER-sized overshoot vs the site.
        var fuels: [FuelType: Double] = [:]
        var ics:   [Interconnector: Double] = [:]
        for (code, mw) in mwByCode {
            let gw = Double(mw) / 1000.0
            if let f = FuelCodeMap.fuel(for: code) {
                fuels[f, default: 0] += gw
            } else if let ic = FuelCodeMap.interconnector(for: code) {
                ics[ic, default: 0] += gw
            }
        }

        // (3) Embedded wind/solar, price and emissions — all from the anchor
        // half-hour (the latest complete one), exactly like the site. NESO
        // publishes forecast rows ahead of time, but the live view must NOT
        // use the period containing the slot — only the completed anchor.
        if let embedded = store.embedded[anchorKey]
            ?? store.embedded.keys.filter({ $0 <= anchorKey }).max().flatMap({ store.embedded[$0] }) {
            fuels[.wind,  default: 0] += Double(embedded.windMW)  / 1000.0
            fuels[.solar, default: 0] += Double(embedded.solarMW) / 1000.0
        }
        let emissions = Double(
            store.emissions[anchorKey]
                ?? store.emissions.keys.filter({ $0 <= anchorKey }).max().flatMap({ store.emissions[$0] })
                ?? 0
        )
        let price = store.price[anchorKey]
            ?? store.price.keys.filter({ $0 <= anchorKey }).max().flatMap({ store.price[$0] })
            ?? 0

        // Match grid.iamkate.com: pumped storage is a TRANSFER, not generation.
        let pumped     = fuels[.pumped] ?? 0
        let generation = fuels.values.reduce(0, +) - pumped
        let transfers  = ics.values.reduce(0, +) + pumped
        let demand     = generation + transfers

        return LiveGrid(
            asOf: slotStart,
            price: price,
            emissions: emissions,
            demand: demand,
            generation: generation,
            transfers: transfers,
            fuels: fuels,
            interconnectors: ics
        )
    }

    private func fallback(store: LiveDataStore, now: Date) -> LiveGrid {
        LiveGrid(asOf: now, price: 0, emissions: 0, demand: 0,
                 generation: 0, transfers: 0, fuels: [:], interconnectors: [:])
    }

    // MARK: - Latest-key lookup

    private func latestKey<V>(in dict: [String: V]) -> String? {
        dict.keys.max()
    }

    // MARK: - Build a time series from the cache

    /// Aggregates the 5-min generation buckets, plus 30-min emissions/price/
    /// embedded buckets, into a `TimeSeries` at the requested granularity.
    private func buildSeries(store: LiveDataStore,
                              from: Date,
                              to: Date,
                              granularity: Granularity) -> TimeSeries {
        let stride: TimeInterval = switch granularity {
        case .halfHour: 30 * 60
        case .hour:     60 * 60
        case .day:      24 * 60 * 60
        case .month:    24 * 60 * 60   // not used for live series
        }
        var bucketStart = APITime.bucket(from, interval: stride)
        let endBucket = APITime.bucket(to, interval: stride)

        var dates: [String] = []
        var price: [Double?] = []
        var emissions: [Double?] = []
        var demand: [Double?] = []
        var generation: [Double?] = []
        var transfers: [Double?] = []
        var fuels: [FuelType: [Double?]] = Dictionary(uniqueKeysWithValues: FuelType.allCases.map { ($0, []) })
        var ics:   [Interconnector: [Double?]] = Dictionary(uniqueKeysWithValues: Interconnector.allCases.map { ($0, []) })

        while bucketStart <= endBucket {
            let bucketEnd = bucketStart.addingTimeInterval(stride)
            // Date-string format must match the granularity so
            // `TimeSeries.parsedDates` can round-trip it.
            dates.append(granularity == .day
                ? String(APITime.iso(bucketStart).prefix(10))
                : APITime.iso(bucketStart))

            let agg = aggregate(store: store, bucketStart: bucketStart, bucketEnd: bucketEnd)
            price.append(agg.price)
            emissions.append(agg.emissions)
            demand.append(agg.demand)
            generation.append(agg.generation)
            transfers.append(agg.transfers)
            for f in FuelType.allCases { fuels[f, default: []].append(agg.fuels[f]) }
            for ic in Interconnector.allCases { ics[ic, default: []].append(agg.interconnectors[ic]) }

            bucketStart = bucketEnd
        }

        return TimeSeries(
            from: dates.first ?? "",
            to: dates.last ?? "",
            granularity: granularity,
            dates: dates,
            price: price,
            emissions: emissions,
            demand: demand,
            generation: generation,
            transfers: transfers,
            fuels: fuels,
            interconnectors: ics
        )
    }

    /// Aggregates all raw cache readings within `[bucketStart, bucketEnd)` into
    /// the single set of metrics shown at that point on the chart.
    private struct AggregatedBucket {
        var price: Double?
        var emissions: Double?
        var demand: Double?
        var generation: Double?
        var transfers: Double?
        var fuels: [FuelType: Double] = [:]
        var interconnectors: [Interconnector: Double] = [:]
    }

    private func aggregate(store: LiveDataStore, bucketStart: Date, bucketEnd: Date) -> AggregatedBucket {
        var result = AggregatedBucket()
        let startISO = APITime.iso(bucketStart)
        let endISO   = APITime.iso(bucketEnd)

        // Generation: average all 5-min sub-buckets in the range, per fuel/interconnector code.
        var fuelTotals: [FuelType: (sum: Double, count: Int)] = [:]
        var icTotals:   [Interconnector: (sum: Double, count: Int)] = [:]

        for (key, mwByCode) in store.generation where key >= startISO && key < endISO {
            // Build per-FuelType totals (CCGT + OCGT + OIL → .gas etc.)
            for (code, mw) in mwByCode {
                let gw = Double(mw) / 1000.0
                if let f = FuelCodeMap.fuel(for: code) {
                    var entry = fuelTotals[f] ?? (0, 0)
                    entry.sum += gw
                    fuelTotals[f] = entry
                } else if let ic = FuelCodeMap.interconnector(for: code) {
                    var entry = icTotals[ic] ?? (0, 0)
                    entry.sum += gw
                    icTotals[ic] = entry
                }
            }
            // count once per 5-min bucket, not per code
            for f in fuelTotals.keys { fuelTotals[f]!.count += 1 }
            for i in icTotals.keys { icTotals[i]!.count += 1 }
        }

        // Wait — the loop above increments counts for ALL fuels each bucket, which over-counts.
        // Restructure: count distinct buckets that contributed.
        var contributingBuckets = 0
        for (key, _) in store.generation where key >= startISO && key < endISO {
            _ = key
            contributingBuckets += 1
        }
        if contributingBuckets > 0 {
            // recompute totals cleanly
            fuelTotals.removeAll()
            icTotals.removeAll()
            for (key, mwByCode) in store.generation where key >= startISO && key < endISO {
                for (code, mw) in mwByCode {
                    let gw = Double(mw) / 1000.0
                    if let f = FuelCodeMap.fuel(for: code) {
                        fuelTotals[f, default: (0, 0)].sum += gw
                    } else if let ic = FuelCodeMap.interconnector(for: code) {
                        icTotals[ic, default: (0, 0)].sum += gw
                    }
                }
            }
            for f in fuelTotals.keys { fuelTotals[f]!.count = contributingBuckets }
            for i in icTotals.keys { icTotals[i]!.count = contributingBuckets }

            for (f, entry) in fuelTotals {
                result.fuels[f] = entry.sum / Double(entry.count)
            }
            for (ic, entry) in icTotals {
                result.interconnectors[ic] = entry.sum / Double(entry.count)
            }
        }

        // Fold embedded wind / solar (NESO) into the wind & solar totals.
        var embedWindSum = 0.0, embedSolarSum = 0.0, embedCount = 0
        for (key, reading) in store.embedded where key >= startISO && key < endISO {
            _ = key
            embedWindSum += Double(reading.windMW) / 1000.0
            embedSolarSum += Double(reading.solarMW) / 1000.0
            embedCount += 1
        }
        if embedCount > 0 {
            result.fuels[.wind] = (result.fuels[.wind] ?? 0) + embedWindSum / Double(embedCount)
            result.fuels[.solar] = (result.fuels[.solar] ?? 0) + embedSolarSum / Double(embedCount)
        }

        // Emissions: average actual/forecast over the bucket.
        var emisSum = 0.0, emisCount = 0
        for (key, v) in store.emissions where key >= startISO && key < endISO {
            _ = key
            emisSum += Double(v)
            emisCount += 1
        }
        if emisCount > 0 { result.emissions = emisSum / Double(emisCount) }

        // Price.
        var priceSum = 0.0, priceCount = 0
        for (key, v) in store.price where key >= startISO && key < endISO {
            _ = key
            priceSum += v
            priceCount += 1
        }
        if priceCount > 0 { result.price = priceSum / Double(priceCount) }

        // Derived: generation total, transfers total, demand = generation + transfers.
        // Match grid.iamkate.com: pumped storage is a TRANSFER, not generation.
        let pumped = result.fuels[.pumped] ?? 0
        if !result.fuels.isEmpty {
            result.generation = result.fuels.values.reduce(0, +) - pumped
        }
        if !result.interconnectors.isEmpty || result.fuels[.pumped] != nil {
            result.transfers = result.interconnectors.values.reduce(0, +) + pumped
        }
        if let g = result.generation, let t = result.transfers {
            result.demand = g + t
        }

        return result
    }
}
