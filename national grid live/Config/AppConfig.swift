import Foundation

struct AppConfig: Sendable {
    enum LiveSource: Sendable {
        case mock
        /// Real upstream APIs (Elexon FUELINST + market-index, Carbon Intensity,
        /// NESO embedded CSV) with append-only on-disk caching.
        case real
    }

    enum SnapshotSource: Sendable {
        case mock
        case url(URL)
    }

    let live: LiveSource
    let snapshot: SnapshotSource
    let refreshInterval: Duration

    /// v1 default: real live data, mocked historical snapshot.
    /// Flip `snapshot` to `.url(...)` once the C# backfill service is hosted.
    static let `default` = AppConfig(
        live: .real,
        snapshot: .mock,
        refreshInterval: .seconds(300)
    )

    @MainActor
    func makeStore() -> GridStore {
        let liveProvider: any LiveDataProvider = {
            switch live {
            case .mock:
                return MockLiveProvider()
            case .real:
                do {
                    return try LiveDataAggregator()
                } catch {
                    // If the on-disk cache can't be created, degrade to the mock.
                    return MockLiveProvider()
                }
            }
        }()

        let snapshotProvider: any SnapshotProvider = {
            switch snapshot {
            case .mock:
                return MockSnapshotProvider()
            case .url(let url):
                return URLSessionSnapshotProvider(url: url)
            }
        }()

        // Snapshot still rides through the blob CachingSnapshotProvider for the
        // last-known-good behaviour. Live uses LiveDataAggregator's own internal
        // cache (so we don't wrap it again).
        let cachingSnapshot: any SnapshotProvider
        do {
            cachingSnapshot = try CachingSnapshotProvider(inner: snapshotProvider)
        } catch {
            cachingSnapshot = snapshotProvider
        }
        return GridStore(live: liveProvider, snapshot: cachingSnapshot)
    }
}
