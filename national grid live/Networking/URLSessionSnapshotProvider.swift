import Foundation

struct URLSessionSnapshotProvider: SnapshotProvider {
    enum Failure: LocalizedError {
        case badStatus(Int)
        var errorDescription: String? {
            switch self {
            case .badStatus(let code): "Snapshot service returned HTTP \(code)"
            }
        }
    }

    let url: URL
    let session: URLSession

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func fetch() async throws -> Snapshot {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw Failure.badStatus(http.statusCode)
        }
        return try Snapshot.decoder.decode(Snapshot.self, from: data)
    }
}
