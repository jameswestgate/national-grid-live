import Foundation
import Observation

@Observable
final class GridStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var live: LiveData?
    private(set) var snapshot: Snapshot?
    private(set) var liveState: LoadState = .idle
    private(set) var snapshotState: LoadState = .idle

    private let liveProvider: any LiveDataProvider
    private let snapshotProvider: any SnapshotProvider

    init(live: any LiveDataProvider, snapshot: any SnapshotProvider) {
        self.liveProvider = live
        self.snapshotProvider = snapshot
    }

    /// Read cached values on launch so the UI can render immediately
    /// before any network refresh completes.
    func primeFromCache() {
        if let cached = liveProvider.cachedValue() {
            self.live = cached
            self.liveState = .loaded
        }
        if let cached = snapshotProvider.cachedValue() {
            self.snapshot = cached
            self.snapshotState = .loaded
        }
    }

    func refresh() async {
        async let liveTask: Void = loadLive()
        async let snapshotTask: Void = loadSnapshotIfNeeded()
        _ = await (liveTask, snapshotTask)
    }

    func loadLive() async {
        liveState = .loading
        do {
            live = try await liveProvider.fetch()
            liveState = .loaded
        } catch {
            // Keep cached `live` visible; mark state as failed so UI can show a banner.
            liveState = .failed(error.localizedDescription)
        }
    }

    func loadSnapshotIfNeeded() async {
        snapshotState = .loading
        do {
            snapshot = try await snapshotProvider.fetch()
            snapshotState = .loaded
        } catch {
            snapshotState = .failed(error.localizedDescription)
        }
    }
}

extension GridStore {
    static func mock() -> GridStore {
        GridStore(live: MockLiveProvider(), snapshot: MockSnapshotProvider())
    }
}
