import Foundation

struct ElexonClient: Sendable {
    let http: HTTPJSONClient
    var host = URL(string: "https://data.elexon.co.uk/bmrs/api/v1")!

    init(http: HTTPJSONClient = HTTPJSONClient()) {
        self.http = http
    }

    // MARK: - FUELINST (5-minute generation by fuel type)

    struct FuelInstItem: Decodable {
        let startTime: String
        let fuelType: String
        let generation: Int    // MW
    }

    func fetchFuelInst(from: Date, to: Date) async throws -> [FuelInstItem] {
        var components = URLComponents(url: host.appendingPathComponent("datasets/FUELINST/stream"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "publishDateTimeFrom", value: APITime.iso(from)),
            URLQueryItem(name: "publishDateTimeTo",   value: APITime.iso(to)),
            URLQueryItem(name: "format",              value: "json")
        ]
        guard let url = components.url else { throw HTTPJSONClient.Failure.transport(URLError(.badURL), url: host) }
        return try await http.get(url)
    }

    // MARK: - Market index price (30-min APX MID)

    struct MarketIndexEnvelope: Decodable {
        let data: [Item]
        struct Item: Decodable {
            let startTime: String
            let price: Double
        }
    }

    func fetchMarketIndex(from: Date, to: Date) async throws -> [MarketIndexEnvelope.Item] {
        var components = URLComponents(url: host.appendingPathComponent("balancing/pricing/market-index"),
                                       resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "from",          value: APITime.iso(from)),
            URLQueryItem(name: "to",            value: APITime.iso(to)),
            URLQueryItem(name: "dataProviders", value: "APXMIDP"),
            URLQueryItem(name: "format",        value: "json")
        ]
        guard let url = components.url else { throw HTTPJSONClient.Failure.transport(URLError(.badURL), url: host) }
        let envelope: MarketIndexEnvelope = try await http.get(url)
        return envelope.data
    }
}
