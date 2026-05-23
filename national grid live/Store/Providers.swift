import Foundation

protocol LiveDataProvider: Sendable {
    func fetch() async throws -> LiveData
}

protocol SnapshotProvider: Sendable {
    func fetch() async throws -> Snapshot
}
