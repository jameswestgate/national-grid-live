import Foundation

struct CarbonIntensityClient: Sendable {
    let http: HTTPJSONClient
    var host = URL(string: "https://api.carbonintensity.org.uk")!

    init(http: HTTPJSONClient = HTTPJSONClient()) {
        self.http = http
    }

    struct Envelope: Decodable {
        let data: [Item]
        struct Item: Decodable {
            let from: String
            let to: String
            let intensity: Intensity

            struct Intensity: Decodable {
                let forecast: Int?
                let actual: Int?
                let index: String?
            }

            /// Actual reading where available, falling back to the forecast.
            var value: Int? { intensity.actual ?? intensity.forecast }
        }
    }

    /// 24-hour rolling window ending at `at`.
    func fetchPT24H(at: Date = .now) async throws -> [Envelope.Item] {
        var url = host.appendingPathComponent("intensity")
        url = url.appendingPathComponent(APITime.iso(at))
        url = url.appendingPathComponent("pt24h")
        let envelope: Envelope = try await http.get(url)
        return envelope.data
    }

    /// Explicit range, capped at 14 days by the upstream API.
    func fetchRange(from: Date, to: Date) async throws -> [Envelope.Item] {
        var url = host.appendingPathComponent("intensity")
        url = url.appendingPathComponent(APITime.iso(from))
        url = url.appendingPathComponent(APITime.iso(to))
        let envelope: Envelope = try await http.get(url)
        return envelope.data
    }
}
