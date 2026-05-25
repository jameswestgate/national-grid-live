import Foundation

struct HTTPJSONClient: Sendable {
    enum Failure: LocalizedError {
        case badStatus(Int, url: URL)
        case decode(underlying: Error, url: URL)
        case transport(Error, url: URL)

        var errorDescription: String? {
            switch self {
            case .badStatus(let code, let url): "HTTP \(code) from \(url.host ?? url.absoluteString)"
            case .decode(let underlying, _):    "Decode failed: \(underlying.localizedDescription)"
            case .transport(let underlying, _): "Network: \(underlying.localizedDescription)"
            }
        }
    }

    let session: URLSession
    let userAgent: String

    init(session: URLSession = .shared,
         userAgent: String = "national-grid-live/1.0 (iOS)") {
        self.session = session
        self.userAgent = userAgent
    }

    func get<T: Decodable>(_ url: URL, decoder: JSONDecoder = JSONDecoder()) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadRevalidatingCacheData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Failure.transport(error, url: url)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw Failure.badStatus(http.statusCode, url: url)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw Failure.decode(underlying: error, url: url)
        }
    }

    /// Plain-text GET, used for the NESO CSV.
    func getText(_ url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadRevalidatingCacheData

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw Failure.transport(error, url: url)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw Failure.badStatus(http.statusCode, url: url)
        }

        return String(decoding: data, as: UTF8.self)
    }
}

/// Shared ISO-8601 (no fractional seconds, UTC suffix) formatter the way the
/// PHP `gmdate('Y-m-d\TH:i:s\Z')` writes it. Marked `nonisolated` so it can
/// run from background contexts (the project's default actor isolation is
/// MainActor, which doesn't suit a pure stateless helper).
nonisolated enum APITime {
    static func iso(_ date: Date) -> String {
        formatter.string(from: date)
    }

    static func parse(_ string: String) -> Date? {
        formatter.date(from: string) ?? formatterWithoutSeconds.date(from: string)
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return f
    }()

    private static let formatterWithoutSeconds: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm'Z'"
        return f
    }()

    /// Round a date down to the nearest `interval` seconds.
    static func bucket(_ date: Date, interval: TimeInterval) -> Date {
        let t = date.timeIntervalSince1970
        let bucketed = floor(t / interval) * interval
        return Date(timeIntervalSince1970: bucketed)
    }
}
