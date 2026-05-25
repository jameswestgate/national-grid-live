import Foundation

/// Append-only on-disk store of the raw 5/30-minute readings from the live
/// APIs. Keyed by ISO-8601 timestamp strings so it round-trips JSON cleanly.
/// Trim keeps the window to the last 7 days.
struct LiveDataStore: Codable, Equatable {
    /// 5-minute buckets of generation. Outer key is bucket start (ISO),
    /// inner key is the Elexon fuel/interconnector code (e.g. "CCGT", "INTFR")
    /// and value is the reading in MW.
    var generation: [String: [String: Int]] = [:]

    /// 30-minute buckets of emissions in gCO₂/kWh.
    var emissions: [String: Int] = [:]

    /// 30-minute buckets of market-index price in £/MWh.
    var price: [String: Double] = [:]

    /// 30-minute buckets of embedded wind & solar generation in MW (from NESO).
    var embedded: [String: EmbeddedReading] = [:]

    var lastFetchedAt: Date?

    struct EmbeddedReading: Codable, Equatable {
        var windMW: Int
        var solarMW: Int
    }

    mutating func trim(olderThan cutoff: Date) {
        let cutoffStr = APITime.iso(cutoff)
        generation = generation.filter { $0.key >= cutoffStr }
        emissions  = emissions.filter  { $0.key >= cutoffStr }
        price      = price.filter      { $0.key >= cutoffStr }
        embedded   = embedded.filter   { $0.key >= cutoffStr }
    }

    /// Latest 5-minute generation bucket present in the cache (highest ISO key).
    var latestGenerationTime: Date? {
        generation.keys.max().flatMap(APITime.parse(_:))
    }

    var latestEmissionsTime: Date? {
        emissions.keys.max().flatMap(APITime.parse(_:))
    }

    var latestPriceTime: Date? {
        price.keys.max().flatMap(APITime.parse(_:))
    }

    var latestEmbeddedTime: Date? {
        embedded.keys.max().flatMap(APITime.parse(_:))
    }
}
