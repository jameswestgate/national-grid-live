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

    private(set) var live: LiveGrid?
    private(set) var snapshot: Snapshot?
    private(set) var liveState: LoadState = .idle
    private(set) var snapshotState: LoadState = .idle

    private let liveProvider: any LiveGridProvider
    private let snapshotProvider: any SnapshotProvider

    init(live: any LiveGridProvider, snapshot: any SnapshotProvider) {
        self.liveProvider = live
        self.snapshotProvider = snapshot
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
            liveState = .failed(error.localizedDescription)
        }
    }

    func loadSnapshotIfNeeded() async {
        guard snapshot == nil else { return }
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
