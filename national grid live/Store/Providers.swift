import Foundation

protocol LiveDataProvider: Sendable {
    func fetch() async throws -> LiveData
    /// Synchronous read of any cached value. Used to render immediately on
    /// launch before a network refresh completes. Default returns nil.
    func cachedValue() -> LiveData?
}

extension LiveDataProvider {
    func cachedValue() -> LiveData? { nil }
}

protocol SnapshotProvider: Sendable {
    func fetch() async throws -> Snapshot
    func cachedValue() -> Snapshot?
}

extension SnapshotProvider {
    func cachedValue() -> Snapshot? { nil }
}
