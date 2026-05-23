import Foundation

struct Snapshot: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let generated: Date
    let sources: SourceAttributions
    let year: TimeSeries
    let allTime: TimeSeries

    struct SourceAttributions: Codable, Sendable, Equatable {
        let elexon: String
        let carbonIntensity: String
        let neso: String
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
