import Foundation
import os

/// Implements `LiveDataProvider` by polling the three public APIs, merging
/// the deltas into an append-only on-disk store, and composing the result
/// into a `LiveData` (current point + 30-min past-day + 30-min past-week).
///
/// Design notes:
/// - On every refresh we ask each API for `[lastBucketInCache, now]` so we
///   only ever pull the few new buckets since the last refresh.
/// - On first launch the cache is empty, so each API is asked for a 24-hour
///   window (Elexon FUELINST / market-index / Carbon Intensity all return up
///   to that natively). The past-day chart populates instantly; the past-week
///   chart fills in as the cache accumulates over the next 7 days.
/// - The store trims everything older than 7 days on every refresh.
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
        let cutoff = nowDate.addingTimeInterval(-7 * 24 * 60 * 60)

        // First-launch fallback windows when the cache is empty.
        let genFrom    = store.latestGenerationTime ?? nowDate.addingTimeInterval(-24 * 60 * 60)
        let emisFrom   = store.latestEmissionsTime  ?? nowDate.addingTimeInterval(-24 * 60 * 60)
        let priceFrom  = store.latestPriceTime      ?? nowDate.addingTimeInterval(-24 * 60 * 60)
        let embedFrom  = store.latestEmbeddedTime   ?? nowDate.addingTimeInterval(-24 * 60 * 60)

        // Fetch the four sources in parallel.
        async let genItems    = elexon.fetchFuelInst(from: genFrom, to: nowDate)
        async let priceItems  = elexon.fetchMarketIndex(from: priceFrom, to: nowDate)
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

    // MARK: - Compose LiveData

    /// Turn the raw cache into the view-ready `LiveData`:
    /// - `current`: latest 5-min bucket of FUELINST data + matching 30-min
    ///   emissions/price/embedded buckets
    /// - `day`:     last 24h, downsampled to 30-min (48 points)
    /// - `week`:    last 7d, downsampled to 30-min (336 points; fills in over time)
    func compose(from store: LiveDataStore, now: Date) -> LiveData {
        let dayStart  = APITime.bucket(now.addingTimeInterval(-24 * 60 * 60),         interval: 30 * 60)
        let weekStart = APITime.bucket(now.addingTimeInterval(-7 * 24 * 60 * 60),     interval: 30 * 60)

        let day  = buildSeries(store: store, from: dayStart,  to: now, granularity: .halfHour)
        let week = buildSeries(store: store, from: weekStart, to: now, granularity: .hour)
        let current = currentPoint(store: store, now: now)
        return LiveData(current: current, day: day, week: week)
    }

    // MARK: - Current point

    /// Composes a `LiveGrid` that matches the website's "current" KPI selection:
    /// the latest 5-minute FUELINST slot drives the displayed time, fuels and
    /// interconnectors; the 30-minute bucket *containing* that slot supplies
    /// emissions, price and embedded values. If the matching half-hour bucket
    /// hasn't been published yet for any of those slower sources, we fall back
    /// to its most recent available value (the site does the same — emissions
    /// can lag generation by 30+ minutes and the displayed page never blanks).
    /// Mirrors the website's "current" KPI selection exactly.
    ///
    /// The site reads from a MariaDB that's refreshed every 5 min by cron.
    /// Empirically (`grid.iamkate.com` at 09:27 UTC showed `10:15am` BST, price
    /// 88.63 for the 08:30 slot, emissions 85 for the same 08:30 slot) the
    /// site's selection rules are:
    ///
    /// 1. **Anchor**: the latest 30-min slot where **emissions** has data
    ///    (emissions is the slowest of the three half-hour sources).
    /// 2. **price**, **embedded wind/solar**: come from the same anchor slot.
    ///    Even if the next half-hour's price is already published, the site
    ///    uses the anchor's value for consistency.
    /// 3. **Generation/transfers**: the latest FUELINST 5-min slot whose
    ///    startTime is within the half-hour *after* the anchor — i.e. the
    ///    current half-hour. This gives a fresh fuel mix without lagging by a
    ///    full half-hour.
    /// 4. **Displayed time** (`asOf`): the startTime of that 5-min FUELINST slot.
    private func currentPoint(store: LiveDataStore, now: Date) -> LiveGrid {
        // (1) Anchor: latest emissions half-hour, fall back to price/embedded
        //     if emissions has no data yet (early state).
        guard let anchorKey = store.emissions.keys.max()
            ?? store.price.keys.max()
            ?? store.embedded.keys.max(),
              let anchorStart = APITime.parse(anchorKey) else {
            return fallback(store: store, now: now)
        }
        let anchorEnd = anchorStart.addingTimeInterval(30 * 60)

        // (3) 5-min FUELINST slot: latest startTime strictly inside the
        //     half-hour following the anchor (so we render the *current* fuel
        //     mix, not the anchor's). If we don't have a slot there yet, walk
        //     back to the latest available FUELINST slot.
        let halfHourAfterAnchorEnd = anchorEnd.addingTimeInterval(30 * 60)
        let candidateKeys = store.generation.keys
            .filter { key in
                guard let t = APITime.parse(key) else { return false }
                return t >= anchorEnd && t < halfHourAfterAnchorEnd
            }
            .sorted()
        let slotKey: String = candidateKeys.last ?? store.generation.keys.max() ?? ""
        guard let slotStart = APITime.parse(slotKey),
              let mwByCode = store.generation[slotKey], !mwByCode.isEmpty else {
            return fallback(store: store, now: now)
        }

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

        // (2a) Embedded wind/solar — pull the half-hour bucket that *contains*
        // the displayed 5-minute FUELINST slot. NESO forecasts publish ahead of
        // time so embedded.keys.max() may be a future period; the site doesn't
        // use those — it uses the period the displayed time sits inside.
        let slotHalfHourKey = APITime.iso(APITime.bucket(slotStart, interval: 30 * 60))
        if let embedded = store.embedded[slotHalfHourKey]
            ?? store.embedded.keys.filter({ $0 <= slotHalfHourKey }).max().flatMap({ store.embedded[$0] }) {
            fuels[.wind,  default: 0] += Double(embedded.windMW)  / 1000.0
            fuels[.solar, default: 0] += Double(embedded.solarMW) / 1000.0
        }
        let emissions = Double(store.emissions[anchorKey] ?? 0)
        let price     = store.price[anchorKey] ?? 0

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
        let stride: TimeInterval = (granularity == .halfHour) ? 30 * 60 : 60 * 60
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
            dates.append(APITime.iso(bucketStart))

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
