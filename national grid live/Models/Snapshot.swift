import Foundation

struct Snapshot: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let generated: Date
    let sources: SourceAttributions
    let year: Series
    let allTime: Series

    struct SourceAttributions: Codable, Sendable, Equatable {
        let elexon: String
        let carbonIntensity: String
        let neso: String
    }

    enum Granularity: String, Codable, Sendable {
        case day, month
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
