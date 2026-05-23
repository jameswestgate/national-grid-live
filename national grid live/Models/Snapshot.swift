import Foundation

struct Snapshot: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let generated: Date
    let sources: SourceAttributions
    let day: Series
    let week: Series
    let year: Series
    let allTime: Series

    struct SourceAttributions: Codable, Sendable, Equatable {
        let elexon: String
        let carbonIntensity: String
        let neso: String
    }

    enum Granularity: String, Codable, Sendable {
        case halfHour, hour, day, month
    }

    struct Series: Codable, Sendable, Equatable {
        let from: String
        let to: String
        let granularity: Granularity
        let dates: [String]
        let price: [Double?]
        let emissions: [Double?]
        let demand: [Double?]
        let generation: [Double?]
        let transfers: [Double?]
        let fuels: [FuelType: [Double?]]
        let interconnectors: [Interconnector: [Double?]]

        var count: Int { dates.count }
    }
}

extension Snapshot.Series {
    var parsedDates: [Date] {
        let formatter = Self.formatter(for: granularity)
        return dates.compactMap { formatter.date(from: $0) }
    }

    private static func formatter(for granularity: Snapshot.Granularity) -> DateFormatter {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        switch granularity {
        case .halfHour, .hour: f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        case .day:             f.dateFormat = "yyyy-MM-dd"
        case .month:           f.dateFormat = "yyyy-MM"
        }
        return f
    }
}

extension Snapshot {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }()
}
