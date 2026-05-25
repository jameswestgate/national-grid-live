import Foundation

struct CachingLiveDataProvider: LiveDataProvider {
    let inner: any LiveDataProvider
    let cache: JSONCache<LiveData>

    init(inner: any LiveDataProvider, cacheFilename: String = "live.json") throws {
        self.inner = inner
        self.cache = try JSONCache(filename: cacheFilename)
    }

    func cachedValue() -> LiveData? {
        cache.read()
    }

    func fetch() async throws -> LiveData {
        let fresh = try await inner.fetch()
        cache.write(fresh)
        return fresh
    }
}

struct CachingSnapshotProvider: SnapshotProvider {
    let inner: any SnapshotProvider
    let cache: JSONCache<Snapshot>

    init(inner: any SnapshotProvider, cacheFilename: String = "snapshot.json") throws {
        self.inner = inner
        self.cache = try JSONCache(filename: cacheFilename, decoder: Snapshot.decoder, encoder: Snapshot.encoder)
    }

    func cachedValue() -> Snapshot? {
        cache.read()
    }

    func fetch() async throws -> Snapshot {
        let fresh = try await inner.fetch()
        cache.write(fresh)
        return fresh
    }
}
